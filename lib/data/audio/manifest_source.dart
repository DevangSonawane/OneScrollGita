import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/audio/audio.dart';

/// Loads the audio manifest from the audio host, keeping the last good copy
/// on the phone so the library works offline.
///
/// [path] is `v2/manifest.json`: the manifest for the vedabase.io dataset ids
/// with English translations. Builds before it read the root `manifest.json`,
/// which stays as it was so their verse ids keep working.
class ManifestSource {
  ManifestSource(this.baseUrl);

  final String baseUrl;
  static const path = 'v2/manifest.json';
  AudioManifest? _cached;

  Future<File> _file() async => File(
    p.join(
      (await getApplicationSupportDirectory()).path,
      'audio_manifest_v2.json',
    ),
  );

  Future<AudioManifest?> load() async {
    if (_cached != null) return _cached;
    final file = await _file();
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final res = await (await client.getUrl(Uri.parse('$baseUrl/$path')))
          .close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        _cached = AudioManifest.fromJson(
          jsonDecode(body) as Map<String, dynamic>,
        );
        await file.writeAsString(body);
      }
      client.close();
    } catch (_) {
      // Offline: use the saved copy below.
    }
    if (_cached == null && await file.exists()) {
      _cached = AudioManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    }
    return _cached;
  }
}
