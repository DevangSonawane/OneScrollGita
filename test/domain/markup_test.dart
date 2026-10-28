import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/markup.dart';

void main() {
  test('plain text is one segment', () {
    expect(parseMarkup('hello'), [const MarkupSegment('hello')]);
  });

  test('italic, bold and nesting', () {
    expect(parseMarkup('a <i>b <b>c</b></i> d'), [
      const MarkupSegment('a '),
      const MarkupSegment('b ', italic: true),
      const MarkupSegment('c', italic: true, bold: true),
      const MarkupSegment(' d'),
    ]);
  });

  test('strict mode rejects unknown and unbalanced tags', () {
    expect(() => parseMarkup('<u>x</u>', strict: true), throwsA(isA<MarkupException>()));
    expect(() => parseMarkup('<i>x', strict: true), throwsA(isA<MarkupException>()));
    expect(() => parseMarkup('x</b>', strict: true), throwsA(isA<MarkupException>()));
    expect(() => parseMarkup('<i><b>x</i></b>', strict: true), throwsA(isA<MarkupException>()));
  });

  test('lenient mode never throws and keeps text', () {
    expect(stripMarkup('<i>x'), 'x');
    expect(stripMarkup('a</b>b'), 'ab');
    expect(stripMarkup('<script>a</script>'), '<script>a</script>'); // not a tag we know: stays text
  });
}
