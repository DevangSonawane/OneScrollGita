class Chapter {
  const Chapter({
    required this.number,
    required this.titleEn,
    required this.titleHi,
    required this.verseCount,
    required this.entryCount,
  });

  final int number;
  final String titleEn;
  final String? titleHi;

  /// Individual verses (what readers count).
  final int verseCount;

  /// Swipe pages (verse ranges count once).
  final int entryCount;

  String title(String languageCode) =>
      languageCode == 'hi' && titleHi != null ? titleHi! : titleEn;

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    number: json['number'] as int,
    titleEn: json['titleEn'] as String,
    titleHi: json['titleHi'] as String?,
    verseCount: json['verseCount'] as int,
    entryCount: json['entryCount'] as int,
  );
}

class ScriptureSource {
  const ScriptureSource({
    required this.name,
    required this.edition,
    required this.rightsHolder,
    required this.attribution,
    required this.datasetVersion,
  });

  final String name;
  final String edition;
  final String rightsHolder;
  final String attribution;
  final String datasetVersion;

  factory ScriptureSource.fromJson(Map<String, dynamic> json) =>
      ScriptureSource(
        name: json['name'] as String,
        edition: json['edition'] as String,
        rightsHolder: json['rightsHolder'] as String,
        attribution: json['attribution'] as String,
        datasetVersion: json['datasetVersion'] as String,
      );
}

class ChaptersIndex {
  const ChaptersIndex({
    required this.chapters,
    required this.source,
    required this.isPlaceholder,
  });

  final List<Chapter> chapters;
  final ScriptureSource source;
  final bool isPlaceholder;

  int get totalEntries => chapters.fold(0, (sum, c) => sum + c.entryCount);

  Chapter chapter(int number) => chapters[number - 1];

  /// Maps a global entry index (0-based, across all chapters) to
  /// (chapter number, index inside that chapter).
  ({int chapter, int index}) locateGlobalIndex(int globalIndex) {
    var remaining = globalIndex;
    for (final c in chapters) {
      if (remaining < c.entryCount) {
        return (chapter: c.number, index: remaining);
      }
      remaining -= c.entryCount;
    }
    throw RangeError.index(globalIndex, chapters, 'globalIndex');
  }

  factory ChaptersIndex.fromJson(Map<String, dynamic> json) => ChaptersIndex(
    chapters: (json['chapters'] as List)
        .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
        .toList(growable: false),
    source: ScriptureSource.fromJson(json['source'] as Map<String, dynamic>),
    isPlaceholder: json['isPlaceholder'] == true,
  );
}
