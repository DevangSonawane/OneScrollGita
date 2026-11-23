import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:versescroll/app/router.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/core/design/native_glass.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/domain/models/app_settings.dart';

import '../helpers.dart';

/// Apple's own glass controls on iOS 26+ beyond the tab bar
/// (docs/PRD_v7.md section 4e): the reader's top bar, the "…" menu, the
/// Continue button and long-press action sheets.
void main() {
  /// Native views created, by view type (without the prefix): their latest
  /// params and id.
  late Map<String, ({int id, Map<Object?, Object?> params})> views;

  /// Every native view by id, for screens with several of one type.
  late Map<int, ({String type, Map<Object?, Object?> params})> byId;

  void fakeUiKit(WidgetTester tester) {
    views = {};
    byId = {};
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') {
        final args = call.arguments as Map<Object?, Object?>;
        final id = args['id']! as int;
        final type = (args['viewType']! as String).replaceFirst(
          nativeViewPrefix,
          '',
        );
        final params = const StandardMessageCodec().decodeMessage(
          ByteData.sublistView(args['params']! as Uint8List),
        ) as Map<Object?, Object?>;
        views[type] = (id: id, params: params);
        byId[id] = (type: type, params: params);
        messenger.setMockMethodCallHandler(
          MethodChannel('$nativeViewPrefix${type}_$id'),
          (c) async {
            if (c.method == 'update') {
              views[type] = (
                id: id,
                params: c.arguments as Map<Object?, Object?>,
              );
              byId[id] = (
                type: type,
                params: c.arguments as Map<Object?, Object?>,
              );
            }
            return null;
          },
        );
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        null,
      ),
    );
  }

  /// An event from a native view, as UIKit would send it.
  Future<void> nativeEvent(
    WidgetTester tester,
    String type,
    String method, [
    Object? args,
  ]) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      '$nativeViewPrefix${type}_${views[type]!.id}',
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
      (_) {},
    );
    await settle(tester);
  }

  /// The native segmented control showing [labels].
  int segmented(List<String> labels) => byId.entries
      .where(
        (e) =>
            e.value.type == 'native_segmented' &&
            listEquals(e.value.params['labels'] as List?, labels),
      )
      .last
      .key;

  Future<void> sendTo(
    WidgetTester tester,
    int id,
    String method,
    Object? a,
  ) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      '${nativeViewPrefix}native_segmented_$id',
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, a)),
      (_) {},
    );
    await settle(tester);
  }

  Future<TestApp> pumpNative(WidgetTester tester) => pumpApp(
    tester,
    nativeTabBar: true,
    glass: GlassMode.full,
    prefs: const {
      SettingsRepository.kFirstLaunch: true,
      SettingsRepository.kLastVerse: 'bg-02-047',
    },
  );

  testWidgets('reader top bar: chapter, summary and language', (tester) async {
    fakeUiKit(tester);
    final app = await pumpNative(tester);
    app.container.read(routerProvider).go('/gita?verse=bg-02-047');
    await settle(tester);

    final bar = views['native_reader_bar']!.params;
    expect(bar['chapterTitle'], startsWith('2.47 · '));
    expect(bar['language'], 'en');

    await nativeEvent(tester, 'native_reader_bar', 'language', 'hi');
    expect(app.container.read(languageProvider), 'hi');
    expect(views['native_reader_bar']!.params['language'], 'hi');

    await nativeEvent(tester, 'native_reader_bar', 'tap', 'chapter');
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"…" opens a native menu with the study tools', (tester) async {
    fakeUiKit(tester);
    final app = await pumpNative(tester);
    app.container.read(routerProvider).go('/gita?verse=bg-02-047');
    await settle(tester);

    final menu = (views['native_button']!.params['menu']! as List)
        .cast<Map<Object?, Object?>>();
    expect(menu.map((m) => m['id']), ['highlight', 'note', 'learn']);
    expect(menu.first['title'], 'Highlight');
    // The inline study row is not shown on iOS 26.
    expect(find.bySemanticsLabel('Hide study tools'), findsNothing);

    await nativeEvent(tester, 'native_button', 'menu', 'highlight');
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('long-press on a favourite uses the native action sheet', (
    tester,
  ) async {
    fakeUiKit(tester);
    final app = await pumpNative(tester);
    await tester.runAsync(() => app.userData.setFavourite('bg-02-047', true));
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('${nativeViewPrefix}native_actions'),
      (c) async {
        calls.add(c);
        return 'remove';
      },
    );
    app.container.read(routerProvider).go('/profile/favourites');
    await settle(tester);
    await tester.longPress(find.textContaining('2.47').first);
    await settle(tester);

    expect(calls.single.method, 'show');
    final actions = ((calls.single.arguments as Map)['actions'] as List)
        .cast<Map<Object?, Object?>>();
    expect(actions.map((a) => a['id']), ['open', 'remove']);
    expect(actions.last['destructive'], isTrue);
    expect(find.text('No favourites yet'), findsOneWidget);
  });

  testWidgets('Profile translation and theme use native segmented controls', (
    tester,
  ) async {
    fakeUiKit(tester);
    final app = await pumpNative(tester);
    app.container.read(routerProvider).go('/profile');
    await settle(tester);

    final language = segmented(['English', 'हिन्दी']);
    expect(byId[language]!.params['compact'], isFalse);
    await sendTo(tester, language, 'select', 1);
    expect(app.container.read(languageProvider), 'hi');

    final theme = segmented(['System', 'Light', 'Dark']);
    await sendTo(tester, theme, 'select', 2);
    expect(app.container.read(settingsProvider).themeMode, AppThemeMode.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('simplified glass keeps every Flutter control', (tester) async {
    fakeUiKit(tester);
    final app = await pumpApp(
      tester,
      nativeTabBar: true,
      glass: GlassMode.solid,
    );
    app.container.read(routerProvider).go('/gita?verse=bg-02-047');
    await settle(tester);
    expect(views, isEmpty);
    expect(find.byType(UiKitView), findsNothing);
    expect(
      GoRouter.of(tester.element(find.byType(Scaffold).first)).state.uri.path,
      '/gita',
    );
  });
}
