import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../application/core_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/ui_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/verse_entry.dart';
import '../../domain/read_rule.dart';
import '../common/common_widgets.dart';
import '../common/qualifying_read.dart';
import '../common/save_toggle_button.dart';

/// Purport page (PRD 5.6): a quiet typeset book page.
class PurportScreen extends ConsumerWidget {
  const PurportScreen({super.key, required this.verseId});

  final String verseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(entryProvider(verseId));
    return Scaffold(
      body: switch (entry) {
        AsyncData(value: final e?) when e.hasPurport => QualifyingRead(
          verseId: e.id,
          dwell: ReadRule.readerDwell,
          child: _PurportBody(entry: e),
        ),
        AsyncData() => const _NoPurport(),
        AsyncError(:final error) => LoadError(
          error: error,
          onRetry: () => ref.invalidate(entryProvider(verseId)),
        ),
        _ => const SizedBox.expand(),
      },
    );
  }
}

class _NoPurport extends StatelessWidget {
  const _NoPurport();

  @override
  Widget build(BuildContext context) {
    final ui = UiStyles(AppColors.of(context));
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This verse has no purport', style: ui.emptyTitle),
            const SizedBox(height: Space.s16),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurportBody extends ConsumerStatefulWidget {
  const _PurportBody({required this.entry});

  final VerseEntry entry;

  @override
  ConsumerState<_PurportBody> createState() => _PurportBodyState();
}

class _PurportBodyState extends ConsumerState<_PurportBody> {
  late final ScrollController _scroll;
  final _progress = ValueNotifier<double>(0);
  bool _controlsDimmed = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(purportOffsetsProvider)[widget.entry.id] ?? 0;
    _scroll = ScrollController(initialScrollOffset: saved)
      ..addListener(_onScroll);
  }

  void _onScroll() {
    final p = _scroll.position;
    ref.read(purportOffsetsProvider)[widget.entry.id] = p.pixels;
    _progress.value = p.maxScrollExtent <= 0
        ? 0
        : (p.pixels / p.maxScrollExtent).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final e = widget.entry;
    final lang = ref.watch(languageProvider);
    final purport = e.purportFor(lang)!;
    final purportLang = purport.isEnglishFallback ? 'en' : lang;
    final top = MediaQuery.paddingOf(context).top;
    final motion = Motion.of(context);

    Widget pad(Widget child, {double bottom = 0}) => SliverToBoxAdapter(
      child: ContentWidth(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Space.readingSide,
            0,
            Space.readingSide,
            bottom,
          ),
          child: child,
        ),
      ),
    );

    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: (n) {
            final dim = n.direction == ScrollDirection.reverse;
            if (n.direction != ScrollDirection.idle && dim != _controlsDimmed) {
              setState(() => _controlsDimmed = dim);
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: top + 72)),
              pad(
                Text('BHAGAVAD-GITA ${e.label}', style: ui.overline),
                bottom: Space.s24,
              ),
              pad(
                VerseTextBlock(entry: e, gap: Space.s24),
                bottom: Space.s32,
              ),
              pad(const Divider(), bottom: Space.s24),
              pad(
                Semantics(
                  header: true,
                  child: Text('PURPORT', style: ui.overline),
                ),
                bottom: Space.s16,
              ),
              if (purport.isEnglishFallback)
                pad(
                  Text(
                    'Purport is available in English.',
                    style: ui.body(size: 14, color: c.textTertiary),
                  ),
                  bottom: Space.s16,
                ),
              // One lazy sliver item per block keeps long purports smooth.
              SliverList.builder(
                itemCount: purport.blocks.length,
                itemBuilder: (context, i) => ContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.readingSide,
                      0,
                      Space.readingSide,
                      Space.paragraph,
                    ),
                    child: PurportBlockView(
                      block: purport.blocks[i],
                      lang: purportLang,
                    ),
                  ),
                ),
              ),
              pad(
                Padding(
                  padding: const EdgeInsets.only(top: Space.s24),
                  child: Center(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Back to verse'),
                    ),
                  ),
                ),
                bottom: MediaQuery.paddingOf(context).bottom + Space.s48,
              ),
            ],
          ),
        ),
        // Reading progress line.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ExcludeSemantics(
            child: ValueListenableBuilder<double>(
              valueListenable: _progress,
              builder: (context, v, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: v,
                  child: Container(height: 2, color: c.accent),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: top + Space.s8,
          left: Space.s16,
          right: Space.s16,
          child: AnimatedOpacity(
            opacity: _controlsDimmed ? 0.7 : 1,
            duration: motion.crossFade,
            child: GlassLayer(
              strength: GlassStrength.light,
              child: Row(
                children: [
                  GlassIconButton(
                    icon: LucideIcons.chevron_left,
                    semanticLabel: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  GlassShape(
                    radius: Touch.minTarget / 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SaveToggleButton(
                          verseId: e.id,
                          kind: SaveKind.favourite,
                        ),
                        SaveToggleButton(
                          verseId: e.id,
                          kind: SaveKind.bookmark,
                        ),
                        Builder(
                          builder: (context) => Pressable(
                            onTap: () => _showTextSize(context),
                            semanticLabel: 'Text size',
                            child: SizedBox.square(
                              dimension: Touch.minTarget,
                              child: Center(
                                child: Text('Aa', style: ui.label(size: 16)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTextSize(BuildContext anchorContext) {
    final box = anchorContext.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset(0, box.size.height + Space.s8));
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close text size',
      barrierColor: Colors.transparent,
      transitionDuration: AppDurations.fast,
      pageBuilder: (context, _, _) => Stack(
        children: [
          Positioned(
            top: origin.dy,
            right: Space.s16,
            child: const _TextSizePopover(),
          ),
        ],
      ),
      transitionBuilder: (context, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    );
  }
}

class _TextSizePopover extends ConsumerWidget {
  const _TextSizePopover();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final step = ref.watch(settingsProvider.select((s) => s.textScaleStep));
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      elevation: 0,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(Space.s16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: c.hairline),
          boxShadow: Elevation.soft(c),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  'Aa',
                  style: ReadingStyles(
                    c,
                    readingScaleSteps[step],
                  ).translation('en'),
                ),
              ),
            ),
            TextSizeSlider(
              step: step,
              onChanged: (s) {
                HapticFeedback.selectionClick();
                ref.read(settingsProvider.notifier).setTextScaleStep(s);
              },
            ),
            Text(_stepNames[step], style: ui.body(size: 13)),
          ],
        ),
      ),
    );
  }
}

const _stepNames = ['Small', 'Medium small', 'Default', 'Large', 'Extra large'];

/// 5-step slider (A ---o--- A).
class TextSizeSlider extends StatelessWidget {
  const TextSizeSlider({
    super.key,
    required this.step,
    required this.onChanged,
  });

  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Row(
      children: [
        ExcludeSemantics(child: Text('A', style: ui.label(size: 13))),
        Expanded(
          child: Slider(
            value: step.toDouble(),
            min: 0,
            max: (readingScaleSteps.length - 1).toDouble(),
            divisions: readingScaleSteps.length - 1,
            label: _stepNames[step],
            semanticFormatterCallback: (v) =>
                'Text size ${_stepNames[v.round()]}',
            onChanged: (v) {
              if (v.round() != step) onChanged(v.round());
            },
          ),
        ),
        ExcludeSemantics(child: Text('A', style: ui.label(size: 20))),
      ],
    );
  }
}
