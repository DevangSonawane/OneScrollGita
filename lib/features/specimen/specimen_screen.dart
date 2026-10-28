import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/verse_entry.dart';

/// Debug-only typography specimen (PRD section 4). The test strings are
/// rendering samples, not scripture.
class SpecimenScreen extends ConsumerWidget {
  const SpecimenScreen({super.key});

  static const _conjuncts = 'क्ष त्र ज्ञ श्र द्ध द्व ह्म ह्य ङ्क्ष ष्ट्र क्त्य स्त्र न्द्र';
  static const _compound = 'प्रत्युत्पन्नमतित्वसंप्रज्ञातसमाधिस्थितप्रज्ञ';
  static const _dandas = 'पङ्क्तिः प्रथमा । पङ्क्तिः द्वितीया ॥ १ ॥';
  static const _hindi = 'ज़िंदगी फ़िक्र ख़ुशी — हँसना चाँद आँगन';
  static const _diacritics = 'ā ī ū ṛ ṝ ḷ ṅ ñ ṭ ḍ ṇ ś ṣ ṁ ḥ — Ā Ī Ū Ṛ Ś Ṣ';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final styles = readingStyles(context, ref);

    Widget sample(String title, String text, TextStyle style) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s16,
        Space.readingSide,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ui.reference),
          const SizedBox(height: Space.s4),
          Text(text, style: style),
        ],
      ),
    );

    final long = List.filled(
      60,
      'Long purport sample paragraph with <i>italic</i> and <b>bold</b> runs '
      'used to test wrapping, line height and scrolling at every size.',
    ).join(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Typography specimen'),
        leading: BackButton(onPressed: () => context.go('/profile')),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: navBarInset(context)),
        children: [
          const SectionHeader('SANSKRIT — NOTO SERIF DEVANAGARI'),
          sample('Conjuncts', _conjuncts, styles.sanskrit.copyWith(fontFamily: Fonts.devanagari)),
          sample('Long compound', _compound, styles.sanskrit.copyWith(fontFamily: Fonts.devanagari)),
          sample('Danda and double danda', _dandas, styles.sanskrit.copyWith(fontFamily: Fonts.devanagari)),
          const SectionHeader('SANSKRIT — TIRO DEVANAGARI SANSKRIT'),
          sample('Conjuncts', _conjuncts, styles.sanskrit.copyWith(fontFamily: Fonts.tiro)),
          sample('Long compound', _compound, styles.sanskrit.copyWith(fontFamily: Fonts.tiro)),
          sample('Danda and double danda', _dandas, styles.sanskrit.copyWith(fontFamily: Fonts.tiro)),
          const SectionHeader('HINDI'),
          sample('Nukta and chandrabindu', _hindi, styles.translation('hi')),
          const SectionHeader('TRANSLITERATION'),
          sample('All diacritics', _diacritics, styles.transliteration),
          const SectionHeader('LONG PURPORT'),
          Padding(
            padding: const EdgeInsets.all(Space.readingSide),
            child: PurportBlockView(
              block: PurportBlock(type: PurportBlockType.paragraph, text: long),
              lang: 'en',
            ),
          ),
        ],
      ),
    );
  }
}
