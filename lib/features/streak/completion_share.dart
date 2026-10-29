import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_links.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/utils/date_format.dart';
import '../../domain/streak.dart';
import '../gita/share_card.dart' show renderToPng;

/// Completion card (PRD_v2 section 8): portrait 1080 x 1350, quiet, no
/// personal data.
class CompletionShareCard extends StatelessWidget {
  const CompletionShareCard({
    super.key,
    required this.stats,
    required this.date,
  });

  final StreakStats stats;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final streak = stats.currentStreak >= 2;
    final size = StreakMetrics.shareCardSize;
    return Container(
      width: size.width,
      height: size.height,
      color: c.bg,
      padding: const EdgeInsets.all(Space.s32),
      child: Column(
        children: [
          Container(width: 32, height: 2, color: c.accent),
          const Spacer(),
          if (streak) ...[
            Text(
              '${stats.currentStreak}',
              style: ui.title.copyWith(
                fontSize: 96,
                height: 1,
                color: c.accentText,
              ),
            ),
            const SizedBox(height: Space.s8),
            Text(
              '${stats.currentStreak}-day reading streak',
              textAlign: TextAlign.center,
              style: ui.emptyTitle,
            ),
          ] else
            Text(
              "I read today's verse",
              textAlign: TextAlign.center,
              style: ui.title,
            ),
          const SizedBox(height: Space.s16),
          Text(
            stats.totalVerses == 1
                ? '1 verse read'
                : '${stats.totalVerses} verses read',
            style: ui.body(size: 15),
          ),
          const SizedBox(height: Space.s4),
          Text(formatLongDate(date), style: ui.body(size: 13)),
          const Spacer(),
          Text('Bhagavad-gita As It Is', style: ui.label(size: 12)),
        ],
      ),
    );
  }
}

/// The share caption, with the store link when one is set.
String completionCaption() {
  const text = "I'm reading the Bhagavad-gita daily.";
  return AppLinks.shareLink.isEmpty ? text : '$text ${AppLinks.shareLink}';
}

/// Renders the card and hands it to the system share sheet. No upload.
Future<void> shareCompletion(
  BuildContext context,
  StreakStats stats,
  DateTime date, {
  Rect? origin,
}) async {
  final png = await renderToPng(
    context,
    CompletionShareCard(stats: stats, date: date),
    size: StreakMetrics.shareCardSize,
  );
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/reading-streak.png');
  await file.writeAsBytes(png, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      text: completionCaption(),
      files: [XFile(file.path, mimeType: 'image/png')],
      sharePositionOrigin: origin,
    ),
  );
}
