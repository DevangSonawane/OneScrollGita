import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/core_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/search_providers.dart';
import '../../application/streak_providers.dart';
import '../../core/config/helpline.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../data/search/search_index.dart';
import '../../domain/search/sensitive.dart';
import '../common/common_widgets.dart';

/// Suggested chips until themes load (PRD_v2 section 10).
const _fallbackChips = [
  'peace of mind',
  'anger',
  'fear',
  'duty',
  'devotion',
  'the soul',
];

/// Keyword and situation search (PRD_v2 sections 10 and 11).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _input = TextEditingController(text: widget.initialQuery);
  final _focus = FocusNode();
  Timer? _debounce;
  late String _query = widget.initialQuery?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    // Start building the index right away.
    ref.read(searchIndexProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () {
      if (mounted) setState(() => _query = text.trim());
    });
    setState(() {}); // clear button
  }

  void _setQuery(String q) {
    _input.text = q;
    _input.selection = TextSelection.collapsed(offset: q.length);
    _debounce?.cancel();
    setState(() => _query = q.trim());
    _remember(q);
  }

  void _remember(String q) {
    final t = q.trim();
    if (t.length < 2 || isSensitiveQuery(t)) return; // never stored
    ref.read(activityRepositoryProvider).addSearch(t).ignore();
  }

  void _open(String id) {
    _remember(_query);
    // go() replaces the stack, which also closes this page.
    openInReader(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: top + Space.s4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(LucideIcons.chevron_left, size: 22),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: Space.s4),
                Expanded(
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: _onChanged,
                    onSubmitted: _setQuery,
                    style: ui.body(color: c.textPrimary, size: 15),
                    decoration: InputDecoration(
                      hintText: 'Search verses or a feeling',
                      hintStyle: ui.body(color: c.textTertiary, size: 15),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Space.s12,
                        vertical: Space.s12,
                      ),
                      filled: true,
                      fillColor: c.surfaceSoft,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: IconSizes.small,
                        color: c.textTertiary,
                      ),
                      suffixIcon: _input.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _input.clear();
                                _focus.requestFocus();
                                _setQuery('');
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.input),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (ref.watch(searchPreparingProvider))
            Padding(
              padding: const EdgeInsets.all(Space.s12),
              child: Text(
                'Preparing search. This happens once.',
                style: ui.body(size: 13, color: c.textTertiary),
              ),
            ),
          Expanded(
            child: ContentWidth(
              child: _query.length < 2
                  ? _Suggestions(onPick: _setQuery)
                  : _Results(query: _query, onOpen: _open),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(languageProvider);
    final recent = ref.watch(searchHistoryProvider).value ?? const [];
    final themes = ref.watch(themesProvider).value;
    final chips = themes == null || themes.isEmpty
        ? _fallbackChips
        : [for (final t in themes.take(12)) t.title.of(lang)];
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: Space.s48),
      children: [
        const _SearchSectionHeader('TRY A FEELING OR TOPIC'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
          child: Wrap(
            spacing: Space.s8,
            runSpacing: Space.s8,
            children: [
              for (final chip in chips)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(chip, style: ui.label(size: 13)),
                  onPressed: () => onPick(chip),
                ),
            ],
          ),
        ),
        if (recent.isNotEmpty) ...[
          _RecentHeader(
            onClear: () =>
                ref.read(activityRepositoryProvider).clearSearchHistory(),
          ),
          for (final q in recent)
            SettingsRow(title: q, onTap: () => onPick(q), showChevron: false),
        ],
      ],
    );
  }
}

class _Results extends ConsumerStatefulWidget {
  const _Results({required this.query, required this.onOpen});

  final String query;
  final ValueChanged<String> onOpen;

  @override
  ConsumerState<_Results> createState() => _ResultsState();
}

class _ResultsState extends ConsumerState<_Results> {
  static const _previewLimit = 2;
  final _expandedSections = <String>{};

  @override
  void didUpdateWidget(covariant _Results oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) _expandedSections.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(languageProvider);
    final async = ref.watch(searchProvider((query: widget.query, lang: lang)));
    final chapters = ref.watch(chaptersIndexProvider).value;
    final outcome = async.value;
    if (outcome == null) {
      return async.hasError
          ? LoadError(
              error: async.error,
              onRetry: () => ref.invalidate(searchIndexProvider),
            )
          : const SizedBox.shrink();
    }

    String chapterTitle(int n) =>
        chapters == null ? 'Chapter $n' : chapters.chapter(n).title(lang);
    Widget entryTile(CatalogueEntry e) => VerseListTile(
      reference: e.label,
      chapterTitle: chapterTitle(e.chapter),
      preview: e.translation(lang),
      previewLocale: lang == 'hi' && e.translationHi != null
          ? const Locale('hi')
          : null,
      compact: true,
      onTap: () => widget.onOpen(e.id),
    );
    Widget translationHitTile(SearchHit h) => VerseListTile(
      reference: h.label,
      chapterTitle: chapterTitle(h.chapter),
      preview: h.snippet,
      highlightPreview: true,
      compact: true,
      onTap: () => widget.onOpen(h.id),
    );
    Widget purportHitTile(SearchHit h) => VerseListTile(
      reference: h.label,
      chapterTitle: chapterTitle(h.chapter),
      preview: h.snippet,
      highlightPreview: true,
      compact: true,
      onTap: () => openPurport(context, h.id),
    );

    final r = outcome.results;
    List<Widget> sectionSlivers<T>({
      required String id,
      required String title,
      required List<T> entries,
      required Widget Function(T entry) item,
    }) {
      final expanded = _expandedSections.contains(id);
      final visible = expanded ? entries : entries.take(_previewLimit).toList();
      return [
        SliverToBoxAdapter(child: _SearchSectionHeader(title)),
        SliverList.builder(
          itemCount: visible.length,
          itemBuilder: (_, index) => Column(
            children: [
              item(visible[index]),
              if (index < visible.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Space.readingSide),
                  child: Divider(height: 1),
                ),
            ],
          ),
        ),
        if (!expanded && entries.length > _previewLimit)
          SliverToBoxAdapter(
            child: _MoreResultsButton(
              count: entries.length - _previewLimit,
              onPressed: () => setState(() => _expandedSections.add(id)),
            ),
          ),
      ];
    }

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        if (outcome.sensitive) const SliverToBoxAdapter(child: _CareMessage()),
        for (final t in outcome.themes) ...[
          ...sectionSlivers<CatalogueEntry>(
            id: 'theme-${t.id}',
            title: 'VERSES ON ${t.title.of(lang).toUpperCase()}',
            entries: outcome.themeEntries[t.id] ?? const [],
            item: entryTile,
          ),
        ],
        if (r.translation.isNotEmpty) ...[
          ...sectionSlivers<SearchHit>(
            id: 'translation',
            title: 'TRANSLATION MATCHES',
            entries: r.translation,
            item: translationHitTile,
          ),
        ],
        if (r.purport.isNotEmpty) ...[
          ...sectionSlivers<SearchHit>(
            id: 'purport',
            title: 'PURPORT MATCHES',
            entries: r.purport,
            item: purportHitTile,
          ),
        ],
        if (outcome.isEmpty ||
            (outcome.themes.isEmpty && r.isEmpty && !outcome.sensitive))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Space.s32),
              child: Text(
                'No verses found. Try a different word.',
                textAlign: TextAlign.center,
                style: ui.body(),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.paddingOf(context).bottom + Space.s48,
          ),
        ),
      ],
    );
  }
}

/// Shown first for sensitive queries. No medical or promise-like wording.
class _CareMessage extends StatelessWidget {
  const _CareMessage();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    const number = HelplineConfig.number;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s12,
        Space.readingSide,
        0,
      ),
      padding: const EdgeInsets.all(Space.s12),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              careMessage,
              style: ui.body(color: c.textPrimary, size: 15),
            ),
          ),
          if (number.isNotEmpty) ...[
            const SizedBox(height: Space.s12),
            TextButton.icon(
              onPressed: () => launchUrl(Uri(scheme: 'tel', path: number)),
              icon: const Icon(Icons.call_rounded),
              label: Text(
                HelplineConfig.label.isEmpty
                    ? 'Call $number'
                    : 'Call ${HelplineConfig.label}: $number',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoreResultsButton extends StatelessWidget {
  const _MoreResultsButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s8,
        Space.readingSide,
        Space.s4,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: c.surfaceSoft,
            foregroundColor: c.textSecondary,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: Space.s12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text('More ($count)', style: ui.label(size: 13)),
        ),
      ),
    );
  }
}

/// Keeps the result-heavy search screen visually compact.
class _SearchSectionHeader extends StatelessWidget {
  const _SearchSectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SectionHeader(
    text,
    padding: const EdgeInsets.fromLTRB(
      Space.readingSide,
      Space.s16,
      Space.readingSide,
      Space.s4,
    ),
  );
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        Space.s16,
        Space.readingSide,
        Space.s4,
      ),
      child: Row(
        children: [
          Expanded(child: Text('RECENT', style: ui.overline)),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: Space.s8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text('Clear', style: ui.label(size: 13)),
          ),
        ],
      ),
    );
  }
}
