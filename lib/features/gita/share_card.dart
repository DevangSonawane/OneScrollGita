import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_links.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/verse_entry.dart';

/// The picture that is shared: a 4:5 card (1080 x 1350 px).
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.entry, required this.lang});

  static const size = Size(360, 450);

  final VerseEntry entry;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final reading = ReadingStyles(c, 1);
    return Container(
      width: size.width,
      height: size.height,
      color: c.bg,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      child: Column(
        children: [
          Container(width: 32, height: 2, color: c.accent),
          const SizedBox(height: Space.s16),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: size.width - 56,
                child: Column(
                  children: [
                    Text(
                      entry.sanskrit.join('\n'),
                      textAlign: TextAlign.center,
                      style: reading.sanskrit.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: Space.s12),
                    Text(
                      entry.transliteration.join('\n'),
                      textAlign: TextAlign.center,
                      style: reading.transliteration.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: Space.s16),
                    Text(
                      entry.translation(lang),
                      textAlign: TextAlign.center,
                      style: reading
                          .translation(entry.hasTranslation(lang) ? lang : 'en')
                          .copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.s16),
          Text('Bhagavad-gītā ${entry.label}', style: ui.label(size: 13)),
          const SizedBox(height: 2),
          Text('Shared from One Scroll Gita', style: ui.body(size: 11)),
        ],
      ),
    );
  }
}

/// Renders [widget] off screen into PNG bytes.
Future<List<int>> renderToPng(
  BuildContext context,
  Widget widget, {
  required Size size,
  double pixelRatio = 3,
}) async {
  final boundary = RenderRepaintBoundary();
  final view = View.of(context);
  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(child: boundary),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(size),
      devicePixelRatio: pixelRatio,
    ),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final buildOwner = BuildOwner(focusManager: FocusManager());
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: Theme(
      data: Theme.of(context),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Directionality(textDirection: TextDirection.ltr, child: widget),
      ),
    ),
  ).attachToRenderTree(buildOwner);
  buildOwner
    ..buildScope(root)
    ..finalizeTree();
  pipeline
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Shares a picture of the verse with its text and link.
Future<void> shareVerse(
  BuildContext context,
  VerseEntry entry,
  String lang, {
  Rect? origin,
}) async {
  final png = await renderToPng(
    context,
    ShareCard(entry: entry, lang: lang),
    size: ShareCard.size,
  );
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/bg-${entry.label.replaceAll('.', '-')}.png');
  await file.writeAsBytes(png, flush: true);
  final text =
      '“${entry.translation(lang)}”\n— Bhagavad-gītā ${entry.label}\n\n'
      'Read it in One Scroll Gita: ${AppLinks.verseUrl(entry.id)}';
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: 'Bhagavad-gītā ${entry.label}',
      files: [XFile(file.path, mimeType: 'image/png')],
      sharePositionOrigin: origin,
    ),
  );
}
