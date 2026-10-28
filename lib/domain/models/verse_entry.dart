/// One swipe page in the reader: a single verse or a range of verses that
/// share one translation and purport in the source edition.
class VerseEntry {
  const VerseEntry({
    required this.id,
    required this.chapter,
    required this.verseStart,
    required this.verseEnd,
    required this.label,
    required this.sanskrit,
    required this.transliteration,
    required this.translationEn,
    required this.translationHi,
    this.purportEn,
    this.purportHi,
  });

  final String id;
  final int chapter;
  final int verseStart;
  final int verseEnd;
  final String label;
  final List<String> sanskrit;
  final List<String> transliteration;
  final String translationEn;
  /// Null when the source has no Hindi translation (shown in English).
  final String? translationHi;
  final List<PurportBlock>? purportEn;
  final List<PurportBlock>? purportHi;

  bool get isRange => verseEnd != verseStart;
  bool get hasPurport =>
      (purportEn?.isNotEmpty ?? false) || (purportHi?.isNotEmpty ?? false);

  /// Number of individual verses covered by this entry.
  int get verseSpan => verseEnd - verseStart + 1;

  bool hasTranslation(String languageCode) =>
      languageCode != 'hi' || (translationHi?.trim().isNotEmpty ?? false);

  /// The translation in [languageCode], falling back to English.
  String translation(String languageCode) =>
      hasTranslation(languageCode) && languageCode == 'hi'
      ? translationHi!
      : translationEn;

  /// The purport to show for [languageCode], and whether it is a fallback to
  /// English because the Hindi purport does not exist.
  ({List<PurportBlock> blocks, bool isEnglishFallback})? purportFor(
    String languageCode,
  ) {
    if (languageCode == 'hi' && (purportHi?.isNotEmpty ?? false)) {
      return (blocks: purportHi!, isEnglishFallback: false);
    }
    if (purportEn?.isNotEmpty ?? false) {
      return (blocks: purportEn!, isEnglishFallback: languageCode == 'hi');
    }
    if (purportHi?.isNotEmpty ?? false) {
      return (blocks: purportHi!, isEnglishFallback: false);
    }
    return null;
  }

  factory VerseEntry.fromJson(Map<String, dynamic> json) {
    final translation = json['translation'] as Map<String, dynamic>;
    final purport = json['purport'] as Map<String, dynamic>?;
    return VerseEntry(
      id: json['id'] as String,
      chapter: json['chapter'] as int,
      verseStart: json['verseStart'] as int,
      verseEnd: json['verseEnd'] as int,
      label: json['label'] as String,
      sanskrit: List<String>.from(json['sanskrit'] as List),
      transliteration: List<String>.from(json['transliteration'] as List),
      translationEn: translation['en'] as String,
      translationHi: translation['hi'] as String?,
      purportEn: _blocks(purport?['en']),
      purportHi: _blocks(purport?['hi']),
    );
  }

  static List<PurportBlock>? _blocks(Object? raw) {
    if (raw is! List) return null;
    return raw
        .map((b) => PurportBlock.fromJson(b as Map<String, dynamic>))
        .toList(growable: false);
  }
}

enum PurportBlockType {
  paragraph('p'),
  quote('quote'),
  sanskrit('sanskrit');

  const PurportBlockType(this.code);
  final String code;

  static PurportBlockType? fromCode(String code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

class PurportBlock {
  const PurportBlock({required this.type, required this.text});

  final PurportBlockType type;
  final String text;

  factory PurportBlock.fromJson(Map<String, dynamic> json) => PurportBlock(
    type:
        PurportBlockType.fromCode(json['type'] as String) ??
        PurportBlockType.paragraph,
    text: json['text'] as String,
  );
}
