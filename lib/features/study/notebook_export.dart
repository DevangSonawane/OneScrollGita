import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../application/core_providers.dart';
import '../../application/premium_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/study_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/copy_on_tap.dart' show showToast;
import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/utils/date_format.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/notebook.dart';
import '../../domain/premium.dart';
import '../common/common_widgets.dart';
import '../premium/paywall_screen.dart';
import '../premium/sadhak_art.dart';

/// Opens the export screen, or the paywall for free users.
void openNotebookExport(BuildContext context, WidgetRef ref) {
  if (canUse(PremiumFeature.notebookExport, ref.read(entitlementProvider))) {
    context.push('/notebook');
  } else {
    openPaywall(context, reason: PremiumFeature.notebookExport);
  }
}

/// Page width in PDF points (A5 is 420 x 595).
const _pageWidth = 420.0;
const _pagePixelRatio = 2.5;

class NotebookExportScreen extends ConsumerStatefulWidget {
  const NotebookExportScreen({super.key});

  @override
  ConsumerState<NotebookExportScreen> createState() =>
      _NotebookExportScreenState();
}

class _NotebookExportScreenState extends ConsumerState<NotebookExportScreen> {
  var _options = const NotebookOptions();
  double? _progress;

  /// Reads an entry while keeping its auto-dispose provider alive.
  Future<VerseEntry?> _entry(String id) async {
    final sub = ref.listenManual(entryProvider(id), (_, _) {});
    try {
      return await ref.read(entryProvider(id).future);
    } finally {
      sub.close();
    }
  }

  Future<void> _export() async {
    final notes = ref.read(notesProvider).value ?? const [];
    final highlights = ref.read(highlightsProvider).value ?? const [];
    final journal = ref.read(journalProvider).value ?? const [];
    final pages = buildNotebook(
      notes: notes,
      highlights: highlights,
      journal: journal,
      options: _options,
    );
    if (pages.isEmpty) {
      showToast(context, 'Nothing to export yet.');
      return;
    }
    setState(() => _progress = 0);
    try {
      final index = await ref.read(chaptersIndexProvider.future);
      final lang = ref.read(languageProvider);
      final now = ref.read(clockProvider)();
      if (!mounted) return;
      final built = await buildNotebookPdf(
        context,
        pages: pages,
        index: index,
        lang: lang,
        now: now,
        entryOf: _entry,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/my-gita-notebook-${now.year}-${now.month}-${now.day}.pdf',
      );
      await file.writeAsBytes(built.pdf, flush: true);
      if (!mounted) return;
      setState(() => _progress = null);
      await SharePlus.instance.share(
        ShareParams(
          subject: 'My Gita notebook',
          files: [XFile(file.path, mimeType: 'application/pdf')],
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _progress = null);
        showToast(context, 'Could not create the PDF. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final n = ref.watch(notesProvider).value?.length ?? 0;
    final h = ref.watch(highlightsProvider).value?.length ?? 0;
    final j = ref.watch(journalProvider).value?.length ?? 0;
    final allowed = canUse(
      PremiumFeature.notebookExport,
      ref.watch(entitlementProvider),
    );
    final busy = _progress != null;
    Widget option(String title, int count, bool value, NotebookOptions next) =>
        CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Space.readingSide,
          ),
          value: value && count > 0,
          onChanged: busy || count == 0
              ? null
              : (_) => setState(() => _options = next),
          title: Text(title, style: ui.label()),
          subtitle: Text(
            count == 0 ? 'None yet' : '$count',
            style: ui.body(size: 14),
          ),
          activeColor: c.accent,
        );
    final o = _options;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gita notebook'),
        leading: LucideBackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.only(bottom: Space.s32),
            children: [
              const SizedBox(height: Space.s16),
              const Center(child: LotusMark(size: PaywallMetrics.lotusIcon)),
              const SizedBox(height: Space.s12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.readingSide,
                ),
                child: Text(
                  'A PDF of your own study, verse by verse: the verse as '
                  'printed, then what you wrote. It is made on this phone '
                  'and only leaves it if you share it.',
                  textAlign: TextAlign.center,
                  style: ui.body(size: 15),
                ),
              ),
              const SectionHeader('INCLUDE'),
              option(
                'Notes',
                n,
                o.notes,
                NotebookOptions(
                  notes: !o.notes,
                  highlights: o.highlights,
                  journal: o.journal,
                ),
              ),
              option(
                'Highlights',
                h,
                o.highlights,
                NotebookOptions(
                  notes: o.notes,
                  highlights: !o.highlights,
                  journal: o.journal,
                ),
              ),
              option(
                'Journal',
                j,
                o.journal,
                NotebookOptions(
                  notes: o.notes,
                  highlights: o.highlights,
                  journal: !o.journal,
                ),
              ),
              const SizedBox(height: Space.s24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.readingSide,
                ),
                child: busy
                    ? Column(
                        children: [
                          LinearProgressIndicator(
                            value: _progress,
                            color: c.accent,
                            backgroundColor: c.surfaceSoft,
                          ),
                          const SizedBox(height: Space.s8),
                          Text('Creating your notebook…', style: ui.body()),
                        ],
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: c.onAccent,
                          minimumSize: const Size.fromHeight(
                            PaywallMetrics.ctaHeight - 4,
                          ),
                        ),
                        onPressed:
                            !allowed || !o.any || (n == 0 && h == 0 && j == 0)
                            ? null
                            : _export,
                        icon: const Icon(LucideIcons.file_down),
                        label: const Text('Create PDF'),
                      ),
              ),
              if (!allowed)
                Center(
                  child: TextButton(
                    onPressed: () => openPaywall(
                      context,
                      reason: PremiumFeature.notebookExport,
                    ),
                    child: const Text('Export is part of Sadhak'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Builds the notebook PDF: a cover, then one page per [pages] item. Each
/// page is drawn by Flutter (so Devanagari is shaped correctly) and placed
/// in the PDF as an image. Returns the PDF bytes and the page pictures.
Future<({Uint8List pdf, List<List<int>> pngs})> buildNotebookPdf(
  BuildContext context, {
  required List<NotebookPage> pages,
  required ChaptersIndex index,
  required String lang,
  required DateTime now,
  required Future<VerseEntry?> Function(String id) entryOf,
  void Function(double progress)? onProgress,
}) async {
  final images = <({List<int> png, Size size})>[
    await renderPage(context, _CoverPage(date: now, pageCount: pages.length)),
  ];
  for (final (i, page) in pages.indexed) {
    final Widget w = switch (page) {
      VersePage() => _VersePageView(
        page: page,
        entry: await entryOf(page.verseId),
        index: index,
        lang: lang,
      ),
      JournalPage() => _JournalPageView(
        page: page,
        entry: page.entry.verseId == null
            ? null
            : await entryOf(page.entry.verseId!),
        lang: lang,
      ),
    };
    if (!context.mounted) break;
    images.add(await renderPage(context, _PageFrame(index: index, child: w)));
    onProgress?.call((i + 1) / pages.length);
  }
  final doc = pw.Document(
    title: 'My Gita notebook',
    creator: 'One Scroll Gita',
  );
  for (final img in images) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          img.size.width,
          img.size.height,
          marginAll: 0,
        ),
        build: (_) => pw.Image(
          pw.MemoryImage(Uint8List.fromList(img.png)),
          fit: pw.BoxFit.fill,
        ),
      ),
    );
  }
  return (pdf: await doc.save(), pngs: [for (final i in images) i.png]);
}

/// Renders [widget] off screen at [_pageWidth], as tall as it needs, always
/// in the light theme (it is paper). Flutter's own text engine shapes the
/// Devanagari, which the `pdf` package cannot.
Future<({List<int> png, Size size})> renderPage(
  BuildContext context,
  Widget widget,
) async {
  final boundary = RenderRepaintBoundary();
  final view = View.of(context);
  final renderView = RenderView(
    view: view,
    child: boundary,
    configuration: const ViewConfiguration(
      logicalConstraints: BoxConstraints(
        minWidth: _pageWidth,
        maxWidth: _pageWidth,
        maxHeight: 14000,
      ),
      devicePixelRatio: _pagePixelRatio,
    ),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final buildOwner = BuildOwner(focusManager: FocusManager());
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: Theme(
      data: buildTheme(Brightness.light),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            heightFactor: 1,
            child: SizedBox(width: _pageWidth, child: widget),
          ),
        ),
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
  final size = boundary.size;
  final image = await boundary.toImage(pixelRatio: _pagePixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return (png: data!.buffer.asUint8List(), size: size);
}

// ---------------------------------------------------------------------------
// Pages (light "paper" look).

class _CoverPage extends StatelessWidget {
  const _CoverPage({required this.date, required this.pageCount});

  final DateTime date;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    const c = AppColors.light;
    final ui = UiStyles(c);
    return Container(
      height: 595,
      color: c.bg,
      padding: const EdgeInsets.all(Space.s48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LotusMark(size: PaywallMetrics.lotusIcon * 2),
          const SizedBox(height: Space.s24),
          Text('My Gita notebook', style: ui.title.copyWith(fontSize: 30)),
          const SizedBox(height: Space.s8),
          Text(formatLongDate(date), style: ui.body(size: 15)),
          const SizedBox(height: Space.s4),
          Text(
            pageCount == 1 ? '1 page' : '$pageCount pages',
            style: ui.body(size: 13, color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Paper, margins and the attribution footer on every page.
class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.index, required this.child});

  final ChaptersIndex index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const c = AppColors.light;
    final ui = UiStyles(c);
    return Container(
      color: c.bg,
      padding: const EdgeInsets.fromLTRB(
        Space.s32,
        Space.s32,
        Space.s32,
        Space.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: Space.s32),
          const Divider(),
          const SizedBox(height: Space.s8),
          Text(
            '${index.source.attribution} Notes and journal are your own '
            "words, not part of Srila Prabhupada's text.",
            style: ui.body(size: 9, color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _VersePageView extends StatelessWidget {
  const _VersePageView({
    required this.page,
    required this.entry,
    required this.index,
    required this.lang,
  });

  final VersePage page;
  final VerseEntry? entry;
  final ChaptersIndex index;
  final String lang;

  @override
  Widget build(BuildContext context) {
    const c = AppColors.light;
    final ui = UiStyles(c);
    final styles = ReadingStyles(c, 0.9);
    final e = entry;
    if (e == null) return const SizedBox.shrink();
    final band = page.highlight == null
        ? null
        : HighlightColors.light.bands[page.highlight!.index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bhagavad-gītā ${e.label}',
          style: ui.title.copyWith(fontSize: 20),
        ),
        Text(
          index.chapter(e.chapter).title(lang),
          style: ui.body(size: 12, color: c.textTertiary),
        ),
        const SizedBox(height: Space.s16),
        Text(
          e.sanskrit.join('\n'),
          textAlign: TextAlign.center,
          style: styles.sanskrit,
        ),
        const SizedBox(height: Space.s8),
        Text(
          e.transliteration.join('\n'),
          textAlign: TextAlign.center,
          style: styles.transliteration,
        ),
        const SizedBox(height: Space.s16),
        Container(
          padding: band == null
              ? EdgeInsets.zero
              : const EdgeInsets.all(Space.s12),
          decoration: BoxDecoration(
            color: band,
            borderRadius: BorderRadius.circular(Radii.input),
          ),
          child: Text(
            e.translation(lang),
            style: styles.translation(e.hasTranslation(lang) ? lang : 'en'),
          ),
        ),
        if (page.note != null) ...[
          const SizedBox(height: Space.s24),
          Text('MY NOTE', style: ui.overline),
          const SizedBox(height: Space.s8),
          Text(page.note!.body, style: ui.body(size: 13, color: c.textPrimary)),
        ],
      ],
    );
  }
}

class _JournalPageView extends StatelessWidget {
  const _JournalPageView({
    required this.page,
    required this.entry,
    required this.lang,
  });

  final JournalPage page;
  final VerseEntry? entry;
  final String lang;

  @override
  Widget build(BuildContext context) {
    const c = AppColors.light;
    final ui = UiStyles(c);
    final e = entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('JOURNAL', style: ui.overline),
        const SizedBox(height: Space.s4),
        Text(
          formatLongDate(page.entry.createdAt),
          style: ui.title.copyWith(fontSize: 18),
        ),
        if (e != null) ...[
          const SizedBox(height: Space.s12),
          Text(
            'On Bhagavad-gītā ${e.label}: “${e.translation(lang)}”',
            style: ReadingStyles(c, 0.8)
                .translation(e.hasTranslation(lang) ? lang : 'en')
                .copyWith(color: c.textSecondary),
          ),
        ],
        const SizedBox(height: Space.s16),
        Text(page.entry.body, style: ui.body(size: 13, color: c.textPrimary)),
      ],
    );
  }
}
