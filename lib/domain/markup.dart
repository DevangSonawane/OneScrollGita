/// Parser for the limited inline markup allowed in purports: `<i>` and `<b>`.
///
/// Never HTML: anything that is not one of the four tags is plain text.
library;

class MarkupSegment {
  const MarkupSegment(this.text, {this.italic = false, this.bold = false});

  final String text;
  final bool italic;
  final bool bold;

  @override
  bool operator ==(Object other) =>
      other is MarkupSegment &&
      other.text == text &&
      other.italic == italic &&
      other.bold == bold;

  @override
  int get hashCode => Object.hash(text, italic, bold);

  @override
  String toString() => 'Seg("$text"${italic ? ' i' : ''}${bold ? ' b' : ''})';
}

class MarkupException implements Exception {
  MarkupException(this.message);
  final String message;
  @override
  String toString() => 'MarkupException: $message';
}

final _tag = RegExp(r'<(/?)([a-zA-Z]+)>');
const _allowed = {'i', 'b'};

/// Parses [input] into styled segments.
///
/// With [strict] (used by the validator) unknown tags and unbalanced markup
/// throw [MarkupException]. Without it, the parser is forgiving: unknown tags
/// stay as text and unclosed tags close at the end.
List<MarkupSegment> parseMarkup(String input, {bool strict = false}) {
  final out = <MarkupSegment>[];
  final stack = <String>[];
  var cursor = 0;

  void emit(String text) {
    if (text.isEmpty) return;
    out.add(
      MarkupSegment(
        text,
        italic: stack.contains('i'),
        bold: stack.contains('b'),
      ),
    );
  }

  for (final m in _tag.allMatches(input)) {
    final closing = m.group(1) == '/';
    final name = m.group(2)!.toLowerCase();
    if (!_allowed.contains(name)) {
      if (strict) throw MarkupException('Tag <${m.group(0)}> is not allowed');
      continue;
    }
    emit(input.substring(cursor, m.start));
    cursor = m.end;
    if (!closing) {
      if (stack.contains(name)) {
        if (strict) throw MarkupException('Nested <$name> inside <$name>');
      }
      stack.add(name);
    } else {
      if (stack.isEmpty || stack.last != name) {
        if (strict) throw MarkupException('Unbalanced </$name>');
        stack.remove(name);
      } else {
        stack.removeLast();
      }
    }
  }
  emit(input.substring(cursor));
  if (strict && stack.isNotEmpty) {
    throw MarkupException('Unclosed <${stack.last}>');
  }
  return _merge(out);
}

/// Text with all allowed tags removed.
String stripMarkup(String input) =>
    parseMarkup(input).map((s) => s.text).join();

List<MarkupSegment> _merge(List<MarkupSegment> segs) {
  final merged = <MarkupSegment>[];
  for (final s in segs) {
    if (merged.isNotEmpty &&
        merged.last.italic == s.italic &&
        merged.last.bold == s.bold) {
      merged[merged.length - 1] = MarkupSegment(
        merged.last.text + s.text,
        italic: s.italic,
        bold: s.bold,
      );
    } else {
      merged.add(s);
    }
  }
  return merged;
}
