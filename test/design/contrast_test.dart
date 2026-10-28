import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/core/design/tokens.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, c) in [('light', AppColors.light), ('dark', AppColors.dark)]) {
    group('$name theme', () {
      final text = {
        'textPrimary': c.textPrimary,
        'textSecondary': c.textSecondary,
        'textTertiary': c.textTertiary,
      };
      final backgrounds = {
        'bg': c.bg,
        'surface': c.surface,
        'surfaceSoft': c.surfaceSoft,
      };
      for (final t in text.entries) {
        for (final b in backgrounds.entries) {
          test('${t.key} on ${b.key} >= 4.5', () {
            expect(contrast(t.value, b.value), greaterThanOrEqualTo(4.5));
          });
        }
      }
      for (final b in {'bg': c.bg, 'surface': c.surface, 'accentSoft': c.accentSoft}.entries) {
        test('accentText on ${b.key} >= 4.5', () {
          expect(contrast(c.accentText, b.value), greaterThanOrEqualTo(4.5));
        });
      }
      for (final b in {'bg': c.bg, 'surface': c.surface}.entries) {
        test('danger on ${b.key} >= 4.5', () {
          expect(contrast(c.danger, b.value), greaterThanOrEqualTo(4.5));
        });
      }
      for (final b in backgrounds.entries) {
        test('accent icons on ${b.key} >= 3', () {
          expect(contrast(c.accent, b.value), greaterThanOrEqualTo(3));
        });
      }
      test('onAccent on accent >= 4.5', () {
        expect(contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
      });
      test('snackbar text (bg on textPrimary) >= 4.5', () {
        expect(contrast(c.bg, c.textPrimary), greaterThanOrEqualTo(4.5));
      });
    });
  }
}
