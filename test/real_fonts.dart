import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's bundled fonts so layout tests measure real text widths
/// (the default test font draws every glyph as a wide square).
Future<void> loadRealFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(
        Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
      );
    }
    await loader.load();
  }

  await load('Inter', ['Inter.ttf']);
  await load('Literata', ['Literata.ttf', 'Literata-Italic.ttf']);
  await load('NotoSerifDevanagari', ['NotoSerifDevanagari.ttf']);
  await load('TiroDevanagariSanskrit', ['TiroDevanagariSanskrit-Regular.ttf']);
}
