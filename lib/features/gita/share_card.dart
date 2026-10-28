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

enum ShareFormat {
  /// 9:16, full screen: Instagram Stories and WhatsApp Status.
  story(Size(360, 640), 'story'),

  /// 4:5: chats and feeds.
  post(Size(360, 450), 'post');

  const ShareFormat(this.size, this.suffix);
  final Size size;
  final String suffix;
}

/// The picture that is shared (1080 px wide).
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.entry,
    required this.lang,
    this.format = ShareFormat.post,
  });

  final VerseEntry entry;
  final String lang;
  final ShareFormat format;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final reading = ReadingStyles(c, 1);
    final story = format == ShareFormat.story;
    final size = format.size;
    // Stories keep clear of the app's own top and bottom bars.
    final padding = story
        ? const EdgeInsets.fromLTRB(32, 96, 32, 88)
        : const EdgeInsets.fromLTRB(28, 28, 28, 20);
    final scale = story ? 1.15 : 1.0;
    return Container(
      width: size.width,
      height: size.height,
      color: c.bg,
      padding: padding,
      child: Column(
        children: [
          Container(width: 32, height: 2, color: c.accent),
          const SizedBox(height: Space.s16),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: size.width - padding.horizontal,
                child: Column(
                  children: [
                    Text(
                      entry.sanskrit.join('\n'),
                      textAlign: TextAlign.center,
                      style: reading.sanskrit.copyWith(fontSize: 20 * scale),
                    ),
                    const SizedBox(height: Space.s12),
                    Text(
                      entry.transliteration.join('\n'),
                      textAlign: TextAlign.center,
                      style: reading.transliteration.copyWith(
                        fontSize: 13 * scale,
                      ),
                    ),
                    const SizedBox(height: Space.s16),
                    Text(
                      entry.translation(lang),
                      textAlign: TextAlign.center,
                      style: reading
                          .translation(entry.hasTranslation(lang) ? lang : 'en')
                          .copyWith(fontSize: 15 * scale),
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
  ShareFormat format = ShareFormat.post,
  Rect? origin,
}) async {
  final png = await renderToPng(
    context,
    ShareCard(entry: entry, lang: lang, format: format),
    size: format.size,
  );
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/bg-${entry.label.replaceAll('.', '-')}-${format.suffix}.png',
  );
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

/// Asks Story or Post. Instagram and WhatsApp then offer Story / Status from
/// the system share sheet.
Future<ShareFormat?> pickShareFormat(BuildContext context) {
  final c = AppColors.of(context);
  final ui = UiStyles(c);
  Widget option(
    BuildContext sheet,
    ShareFormat f,
    IconData icon,
    String title,
    String subtitle,
  ) => ListTile(
    minTileHeight: Touch.minTarget + 16,
    leading: Icon(icon, color: c.accentText),
    title: Text(title, style: ui.label(size: 16)),
    subtitle: Text(subtitle, style: ui.body(size: 13)),
    onTap: () => Navigator.of(sheet).pop(f),
  );
  return showModalBottomSheet<ShareFormat>(
    context: context,
    useRootNavigator: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.readingSide,
                Space.s8,
                Space.readingSide,
                Space.s8,
              ),
              child: Text('Share verse', style: ui.emptyTitle),
            ),
            option(
              sheet,
              ShareFormat.story,
              Icons.smartphone_rounded,
              'Story',
              'Full screen, for Instagram Stories and WhatsApp Status',
            ),
            option(
              sheet,
              ShareFormat.post,
              Icons.crop_portrait_rounded,
              'Post',
              'A card for chats and feeds',
            ),
          ],
        ),
      ),
    ),
  );
}
