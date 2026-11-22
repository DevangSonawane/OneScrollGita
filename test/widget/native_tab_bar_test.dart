import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/core/config/audio_config.dart';
import 'package:versescroll/core/design/glass_nav_bar.dart';
import 'package:versescroll/core/design/native_tab_bar.dart';
import 'package:versescroll/data/platform/ios_version.dart';

import '../helpers.dart';

/// Apple's UIKit tab bar on iOS 26+ (docs/PRD_v7.md section 4e), with the
/// Flutter pill kept as the fallback everywhere else.
void main() {
  group('iOS version', () {
    test('reads the major version', () {
      expect(parseIosMajorVersion('Version 26.1 (Build 23B85)'), 26);
      expect(parseIosMajorVersion('18.6.2'), 18);
      expect(parseIosMajorVersion('26'), 26);
      expect(parseIosMajorVersion('unknown'), isNull);
    });

    test('is null off iOS (the test host)', () {
      expect(iosMajorVersion(), isNull);
    });
  });

  /// Records platform view creation and the bar's update calls.
  late List<Map<Object?, Object?>> created;
  late List<Map<Object?, Object?>> updates;
  late int viewId;

  void fakeUiKit(WidgetTester tester) {
    created = [];
    updates = [];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') {
        final args = call.arguments as Map<Object?, Object?>;
        // Only the tab bar (Home also shows the native Continue button).
        if (args['viewType'] != NativeTabBar.viewType) return null;
        viewId = args['id']! as int;
        final params = const StandardMessageCodec().decodeMessage(
          ByteData.sublistView(args['params']! as Uint8List),
        );
        created.add(params as Map<Object?, Object?>);
        messenger.setMockMethodCallHandler(
          MethodChannel('${NativeTabBar.viewType}_$viewId'),
          (c) async {
            if (c.method == 'update') {
              updates.add(c.arguments as Map<Object?, Object?>);
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

  /// What the native bar sends when a tab is tapped.
  Future<void> nativeTap(WidgetTester tester, int index) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      '${NativeTabBar.viewType}_$viewId',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('select', index),
      ),
      (_) {},
    );
    await settle(tester);
  }

  testWidgets('iOS 26: Apple tab bar replaces the Flutter pill', (
    tester,
  ) async {
    fakeUiKit(tester);
    await pumpApp(tester, nativeTabBar: true, glass: GlassMode.full);

    expect(find.byType(NativeTabBar), findsOneWidget);
    expect(find.byType(GlassNavBar), findsNothing);
    expect(created, hasLength(1));
    final params = created.single;
    expect(params['selected'], 0);
    final items = (params['items']! as List).cast<Map<Object?, Object?>>();
    // One system bar holds every tab, Listen last.
    // Owner's order (2026-11-22): Home, Gita, Listen, Profile.
    expect(items.map((i) => i['label']), [
      'Home',
      'Gita',
      if (AudioConfig.enabled) 'Listen',
      'Profile',
    ]);
    expect(items.first['symbol'], 'house');
    expect(items.last['symbol'], 'person.crop.circle');
  });

  testWidgets('a native tap switches tabs and selection follows', (
    tester,
  ) async {
    fakeUiKit(tester);
    await pumpApp(tester, nativeTabBar: true, glass: GlassMode.full);
    final profile = AudioConfig.enabled ? 3 : 2;

    await nativeTap(tester, profile);
    final router = GoRouter.of(tester.element(find.byType(NativeTabBar)));
    expect(router.state.uri.path, startsWith('/profile'));
    expect(updates.last['selected'], profile);

    await nativeTap(tester, 0);
    expect(updates.last['selected'], 0);

    if (AudioConfig.enabled) {
      await nativeTap(tester, 2);
      expect(router.state.uri.path, startsWith('/listen'));
      expect(updates.last['selected'], 2);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the bar takes the height UIKit reports', (tester) async {
    fakeUiKit(tester);
    await pumpApp(tester, nativeTabBar: true, glass: GlassMode.full);
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      '${NativeTabBar.viewType}_$viewId',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('size', {'width': 390.0, 'height': 83.0}),
      ),
      (_) {},
    );
    await settle(tester);
    expect(tester.getSize(find.byType(NativeTabBar)).height, 83);
  });

  testWidgets('frosted glass still uses the Apple tab bar', (tester) async {
    fakeUiKit(tester);
    await pumpApp(tester, nativeTabBar: true, glass: GlassMode.frosted);
    expect(find.byType(NativeTabBar), findsOneWidget);
  });

  testWidgets('simplified glass falls back to the Flutter pill', (
    tester,
  ) async {
    await pumpApp(tester, nativeTabBar: true, glass: GlassMode.solid);
    expect(find.byType(NativeTabBar), findsNothing);
    expect(find.byType(GlassNavBar), findsOneWidget);
  });

  testWidgets('Android and older iOS keep the Flutter pill', (tester) async {
    await pumpApp(tester, glass: GlassMode.full);
    expect(find.byType(NativeTabBar), findsNothing);
    expect(find.byType(GlassNavBar), findsOneWidget);
  });
}
