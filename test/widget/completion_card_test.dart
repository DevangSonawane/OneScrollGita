import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/core/design/theme.dart';
import 'package:versescroll/core/design/tokens.dart';
import 'package:versescroll/domain/streak.dart';
import 'package:versescroll/features/streak/completion_share.dart';

StreakStats stats(int streak, int verses) => StreakStats(
  currentStreak: streak,
  longestStreak: streak,
  totalDays: streak,
  totalVerses: verses,
  todayCounted: true,
  lastSevenDays: const [false, false, false, false, false, false, true],
);

Future<void> pumpCard(WidgetTester tester, StreakStats s, Brightness b) =>
    tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(b),
        home: Center(
          child: CompletionShareCard(stats: s, date: DateTime(2026, 3, 10)),
        ),
      ),
    );

void main() {
  for (final b in Brightness.values) {
    testWidgets('streak variant, ${b.name}', (tester) async {
      await pumpCard(tester, stats(5, 12), b);
      expect(find.text('5-day reading streak'), findsOneWidget);
      expect(find.text('12 verses read'), findsOneWidget);
      expect(find.text('Bhagavad-gita As It Is'), findsOneWidget);
      expect(
        tester.getSize(find.byType(CompletionShareCard)),
        StreakMetrics.shareCardSize,
      );
    });

    testWidgets('single-day variant, ${b.name}', (tester) async {
      await pumpCard(tester, stats(1, 1), b);
      expect(find.text("I read today's verse"), findsOneWidget);
      expect(find.text('1 verse read'), findsOneWidget);
    });
  }

  test('caption omits the empty store link', () {
    expect(completionCaption(), "I'm reading the Bhagavad-gita daily.");
  });
}
