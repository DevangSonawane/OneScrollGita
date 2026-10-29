/// Written (non-scripture) content: the message bank, chapter summaries and
/// the situation-search theme map. Never attributed to Srila Prabhupada.
library;

/// English and optional Hindi text; Hindi falls back to English.
class LocalText {
  const LocalText(this.en, [this.hi]);

  final String en;
  final String? hi;

  String of(String lang) =>
      lang == 'hi' && (hi?.trim().isNotEmpty ?? false) ? hi! : en;

  factory LocalText.fromJson(Object? json) {
    if (json is String) return LocalText(json);
    final m = json as Map<String, dynamic>;
    return LocalText(m['en'] as String, m['hi'] as String?);
  }
}

enum MessageCategory {
  invite,
  streakRisk('streak_risk'),
  comeback,
  milestone,
  reflection,
  popupGoodWork('popup_good_work'),
  verseLeadIn('verse_lead_in'),
  randomVerse('random_verse');

  const MessageCategory([this._code]);
  final String? _code;

  String get code => _code ?? name;

  static MessageCategory? fromCode(String code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

class Message {
  const Message({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    this.day,
  });

  final String id;
  final MessageCategory category;
  final LocalText title;
  final LocalText body;

  /// Milestone day number (milestone messages only).
  final int? day;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    category: MessageCategory.fromCode(json['category'] as String)!,
    title: LocalText.fromJson(json['title']),
    body: LocalText.fromJson(json['body']),
    day: json['day'] as int?,
  );
}

/// Fills `{streak}` and `{days}`.
String fillPlaceholders(String text, {int? streak, int? days}) => text
    .replaceAll('{streak}', '${streak ?? 0}')
    .replaceAll('{days}', '${days ?? 0}');

class MessageBank {
  MessageBank(List<Message> messages)
    : byCategory = {
        for (final c in MessageCategory.values)
          c: [
            for (final m in messages)
              if (m.category == c) m,
          ],
      },
      byId = {for (final m in messages) m.id: m};

  static final empty = MessageBank(const []);

  final Map<MessageCategory, List<Message>> byCategory;
  final Map<String, Message> byId;

  List<Message> of(MessageCategory c) => byCategory[c] ?? const [];

  /// One of the messages for milestone [day], chosen by [seed].
  Message? milestone(int day, {int seed = 0}) {
    final list = [
      for (final m in of(MessageCategory.milestone))
        if (m.day == day) m,
    ];
    return list.isEmpty ? null : list[seed % list.length];
  }

  factory MessageBank.fromJson(Map<String, dynamic> json) => MessageBank([
    for (final m in json['messages'] as List)
      if (MessageCategory.fromCode((m as Map)['category'] as String) != null)
        Message.fromJson(m as Map<String, dynamic>),
  ]);
}

class ChapterSummary {
  const ChapterSummary({required this.chapter, required this.text});

  final int chapter;
  final LocalText text;

  factory ChapterSummary.fromJson(Map<String, dynamic> json) => ChapterSummary(
    chapter: json['chapter'] as int,
    text: LocalText(json['en'] as String, json['hi'] as String?),
  );
}

/// Shown on every summary (PRD_v2 section 9).
const summaryLabel = "Summary. Not part of Srila Prabhupada's text.";

class SearchTheme {
  const SearchTheme({
    required this.id,
    required this.title,
    required this.synonyms,
    required this.verseIds,
  });

  final String id;
  final LocalText title;
  final List<String> synonyms;

  /// Ranked, 3 to 8 entry ids.
  final List<String> verseIds;

  factory SearchTheme.fromJson(Map<String, dynamic> json) => SearchTheme(
    id: json['id'] as String,
    title: LocalText.fromJson(json['title']),
    synonyms: List<String>.from(json['synonyms'] as List),
    verseIds: List<String>.from(json['verseIds'] as List),
  );
}
