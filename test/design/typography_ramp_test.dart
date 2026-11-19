import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/core/design/tokens.dart';
import 'package:versescroll/core/design/typography.dart';

void main() {
  test('verse text follows one even ramp (PRD_v5 3.1)', () {
    final s = ReadingStyles(AppColors.light, 1);
    final shloka = s.sanskrit.fontSize!;
    final translit = s.transliteration.fontSize!;
    final en = s.translation('en').fontSize!;
    final hi = s.translation('hi').fontSize!;

    expect(shloka, ReadingType.shloka);
    expect(en, hi, reason: 'English and Hindi translations match');
    // Transliteration sits just under the translation, never far below.
    expect(translit, lessThan(en));
    expect(en - translit, lessThanOrEqualTo(1));
    expect(shloka, greaterThan(en));
  });

  test('reading scale applies to every role', () {
    final s = ReadingStyles(AppColors.light, 1.25);
    expect(s.transliteration.fontSize, ReadingType.transliteration * 1.25);
    expect(s.translation('hi').fontSize, ReadingType.translation * 1.25);
  });
}
