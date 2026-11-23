import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/motion.dart';
import '../../core/design/tactile.dart';
import '../../core/design/tokens.dart';
import '../../domain/trainer/trainer.dart';

/// The hidden words of one part, each with where it sits in the verse.
typedef BankSlot = ({String key, String word});

/// The order the bank shows [slots] in: a fixed shuffle, so the same verse
/// always gives the same bank.
List<int> bankOrder(String verseId, List<BankSlot> slots) {
  final order = [for (var i = 0; i < slots.length; i++) i];
  order.sort((a, b) {
    final x = stableSeed('$verseId|${slots[a].key}|${slots[a].word}');
    final y = stableSeed('$verseId|${slots[b].key}|${slots[b].word}');
    return x.compareTo(y);
  });
  return order;
}

/// Fills the blanks of a verse in reading order from a bank of 3D word
/// buttons (owner, 2026-11-23: the same in the trainer and in the
/// first-launch demo). The words are the dataset's own; nothing is changed.
class WordBankController {
  WordBankController(this.verseId, this.slots)
    : order = bankOrder(verseId, slots);

  final String verseId;

  /// In reading order.
  final List<BankSlot> slots;

  /// Bank position → slot index.
  final List<int> order;

  /// Slot keys already filled (by the bank or by tapping the blank).
  final filled = <String>{};

  /// Bank positions already used.
  final used = <int>{};

  int? wrong;
  int wrongCount = 0;

  BankSlot? get next => slots.where((s) => !filled.contains(s.key)).firstOrNull;
  bool get done => next == null;

  /// Returns true when [position]'s word is the next one.
  bool pick(int position) {
    final n = next;
    if (n == null || used.contains(position)) return false;
    if (slots[order[position]].word == n.word) {
      used.add(position);
      filled.add(n.key);
      wrong = null;
      return true;
    }
    wrong = position;
    wrongCount++;
    return false;
  }

  /// A blank tapped for help: fill it and use up one matching button.
  void reveal(String key) {
    final slot = slots.where((s) => s.key == key).firstOrNull;
    if (slot == null || !filled.add(key)) return;
    for (var p = 0; p < order.length; p++) {
      if (!used.contains(p) && slots[order[p]].word == slot.word) {
        used.add(p);
        break;
      }
    }
  }
}

class WordBank extends StatelessWidget {
  const WordBank({
    super.key,
    required this.controller,
    required this.style,
    required this.onPick,
  });

  final WordBankController controller;
  final TextStyle style;

  /// Called with the bank position tapped; the parent calls
  /// [WordBankController.pick] and rebuilds.
  final ValueChanged<int> onPick;

  static ValueKey<String> wordKey(int position) =>
      ValueKey('bankWord-$position');

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final motion = Motion.of(context);
    final b = controller;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Space.s8,
      runSpacing: Space.s8,
      children: [
        for (var p = 0; p < b.order.length; p++)
          AnimatedOpacity(
            opacity: b.used.contains(p) ? 0.3 : 1,
            duration: motion.crossFade,
            child: TactileButton(
              key: wordKey(p),
              semanticLabel: b.slots[b.order[p]].word,
              shakeKey: b.wrong == p ? b.wrongCount : null,
              face: b.wrong == p ? c.danger.withValues(alpha: 0.12) : null,
              border: b.wrong == p ? c.danger : null,
              edge: b.wrong == p ? c.danger.withValues(alpha: 0.5) : null,
              onTap: b.used.contains(p) || b.done
                  ? null
                  : () {
                      final ok = b.next?.word == b.slots[b.order[p]].word;
                      unawaited(
                        ok
                            ? HapticFeedback.lightImpact()
                            : HapticFeedback.heavyImpact(),
                      );
                      onPick(p);
                    },
              child: Text(b.slots[b.order[p]].word, style: style),
            ),
          ),
      ],
    );
  }
}
