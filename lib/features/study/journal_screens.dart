import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/core_providers.dart';
import '../../application/premium_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/study_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/reading_views.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/utils/date_format.dart';
import '../../domain/models/study_items.dart';
import '../../domain/premium.dart';
import '../common/common_widgets.dart';
import '../premium/paywall_screen.dart';

/// Opens the journal, or the paywall for free users.
void openJournal(BuildContext context, WidgetRef ref) {
  if (canUse(PremiumFeature.journal, ref.read(entitlementProvider))) {
    context.push('/journal');
  } else {
    openPaywall(context, reason: PremiumFeature.journal);
  }
}

/// The reflection journal: newest first.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final items = ref.watch(journalProvider);
    final list = items.value ?? const <JournalEntry>[];
    final allowed = canUse(
      PremiumFeature.journal,
      ref.watch(entitlementProvider),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        leading: LucideBackButton(onPressed: () => context.pop()),
      ),
      floatingActionButton: allowed
          ? FloatingActionButton.extended(
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
              onPressed: () => context.push('/journal-edit'),
              icon: const Icon(LucideIcons.pen_line),
              label: const Text('New entry'),
            )
          : null,
      body: !allowed
          ? EmptyState(
              icon: LucideIcons.lock,
              title: 'Your journal is part of Sadhak',
              sentence:
                  'Earlier entries stay on this phone. Sadhak lets you write '
                  'new ones.',
              buttonLabel: 'See Sadhak',
              onPressed: () =>
                  openPaywall(context, reason: PremiumFeature.journal),
            )
          : !items.hasValue
          ? const SizedBox.expand()
          : list.isEmpty
          ? EmptyState(
              icon: LucideIcons.book_heart,
              title: 'Begin your journal',
              sentence:
                  'Write what you are learning, what moved you, or what you '
                  'want to remember.',
              buttonLabel: 'Write the first entry',
              onPressed: () => context.push('/journal-edit'),
            )
          : ContentWidth(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: Space.s48 * 2),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.only(left: Space.readingSide),
                  child: Divider(),
                ),
                itemBuilder: (context, i) {
                  final e = list[i];
                  return InkWell(
                    onTap: () => context.push('/journal-edit?id=${e.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.readingSide,
                        vertical: Space.s16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatLongDate(e.createdAt),
                                  style: ui.reference,
                                ),
                              ),
                              if (e.verseId != null) _VerseChip(e.verseId!),
                            ],
                          ),
                          const SizedBox(height: Space.s8),
                          Text(
                            previewOf(e.body),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: ui.body(size: 15, color: c.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _VerseChip extends ConsumerWidget {
  const _VerseChip(this.verseId);

  final String verseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(entryProvider(verseId)).value;
    if (entry == null) return const SizedBox.shrink();
    return ReferenceChip(label: entry.label);
  }
}

/// A new entry ([id] null, optionally about [verseId]) or an existing one.
class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({super.key, this.id, this.verseId});

  final int? id;
  final String? verseId;

  @override
  ConsumerState<JournalEditorScreen> createState() =>
      _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _text = TextEditingController();
  late final StudyController _study = ref.read(studyControllerProvider);
  Timer? _debounce;
  int? _id;
  String? _verseId;
  DateTime? _createdAt;
  bool _loaded = false;
  bool _deleted = false;
  String _saved = '';
  Future<void>? _saving;

  @override
  void initState() {
    super.initState();
    _id = widget.id;
    _verseId = widget.verseId;
    if (_id == null) {
      _loaded = true;
    } else {
      ref.read(studyRepositoryProvider).journalEntry(_id!).then((e) {
        if (!mounted) return;
        _text.text = e?.body ?? '';
        _saved = _text.text;
        _verseId = e?.verseId;
        _createdAt = e?.createdAt;
        setState(() => _loaded = true);
      });
    }
    _text.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(AppDurations.noteAutosave, _save);
  }

  Future<void> _save() async {
    // One save at a time, so a new entry is never created twice.
    await _saving;
    if (!_loaded || _deleted || _text.text == _saved) return;
    final body = _text.text;
    _saved = body;
    final f = _study.saveJournal(id: _id, verseId: _verseId, body: body);
    _saving = f;
    _id = await f;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _save();
    _text.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete this entry?',
      message: 'It cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _deleted = true;
    _debounce?.cancel();
    await _saving;
    if (_id != null) await _study.deleteJournal(_id!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final lang = ref.watch(languageProvider);
    final entry = _verseId == null
        ? null
        : ref.watch(entryProvider(_verseId!)).value;
    final remaining = StudyLimits.journalMaxChars - _text.text.length;
    return Scaffold(
      appBar: AppBar(
        leading: LucideBackButton(onPressed: () => context.pop()),
        title: Text(formatLongDate(_createdAt ?? ref.read(clockProvider)())),
        actions: [
          if (_saved.trim().isNotEmpty)
            IconButton(
              tooltip: 'Delete entry',
              onPressed: _delete,
              icon: const Icon(LucideIcons.trash),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.readingSide,
              Space.s8,
              Space.readingSide,
              Space.s32,
            ),
            children: [
              if (entry != null) ...[
                Container(
                  padding: const EdgeInsets.all(Space.s16),
                  decoration: BoxDecoration(
                    color: c.surfaceSoft,
                    borderRadius: BorderRadius.circular(Radii.input),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReferenceChip(label: 'Bhagavad-gītā ${entry.label}'),
                      const SizedBox(height: Space.s8),
                      Text(
                        entry.translation(lang),
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: readingStyles(
                          context,
                          ref,
                        ).translation(lang).copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.s16),
              ],
              if (_loaded)
                TextField(
                  controller: _text,
                  autofocus: _text.text.isEmpty,
                  maxLines: null,
                  minLines: 12,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      StudyLimits.journalMaxChars,
                    ),
                  ],
                  style: readingStyles(context, ref).translation('en'),
                  decoration: InputDecoration(
                    hintText: entry == null
                        ? 'What are you learning? What moved you today?'
                        : 'What does this verse ask of you?',
                    hintStyle: ui.body(size: 16, color: c.textTertiary),
                    border: InputBorder.none,
                  ),
                ),
              if (remaining <= StudyLimits.counterWithin)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$remaining characters left',
                    style: ui.body(size: 13, color: c.textTertiary),
                  ),
                ),
              const SizedBox(height: Space.s16),
              Text(
                'Saved on this device as you type.',
                style: ui.body(size: 13, color: c.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
