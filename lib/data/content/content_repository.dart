import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/written_content.dart';

/// Bundled written content (PRD_v2 sections 6, 9, 10, 11).
class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const messagesPath = 'assets/messages/messages.json';
  static const summariesPath = 'assets/summaries/summaries.json';
  static const themesPath = 'assets/search/themes.json';
  static const aliasesPath = 'assets/search/aliases.json';

  final AssetBundle _bundle;

  Future<Map<String, dynamic>> _json(String path) async =>
      jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>;

  Future<MessageBank> messages() async =>
      MessageBank.fromJson(await _json(messagesPath));

  Future<Map<int, ChapterSummary>> summaries() async {
    final json = await _json(summariesPath);
    return {
      for (final s in json['summaries'] as List)
        (s as Map)['chapter'] as int: ChapterSummary.fromJson(
          s as Map<String, dynamic>,
        ),
    };
  }

  Future<List<SearchTheme>> themes() async {
    final json = await _json(themesPath);
    return [
      for (final t in json['themes'] as List)
        SearchTheme.fromJson(t as Map<String, dynamic>),
    ];
  }

  /// Common spelling -> dataset spelling (for example krishna -> kṛṣṇa).
  Future<Map<String, String>> aliases() async {
    final json = await _json(aliasesPath);
    return Map<String, String>.from(json['aliases'] as Map);
  }
}
