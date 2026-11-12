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
import '../../domain/models/study_items.dart';
import '../../domain/premium.dart';
import '../common/common_widgets.dart';
import '../premium/paywall_screen.dart';

/// A private note on one verse. Saves itself while typing and on leave.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.verseId});

  final String verseId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _text = TextEditingController();
  late final StudyController _study = ref.read(studyControllerProvider);
  Timer? _debounce;
  bool _loaded = false;
  bool _deleted = false;
  String _saved = '';

  @override
  void initState() {
    super.initState();
    ref.read(studyRepositoryProvider).note(widget.verseId).then((n) {
      if (!mounted) return;
      _text.text = n?.body ?? '';
      _saved = _text.text;
      setState(() => _loaded = true);
    });
    _text.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {}); // counter
    _debounce?.cancel();
    _debounce = Timer(AppDurations.noteAutosave, _save);
  }

  Future<void> _save() async {
    if (!_loaded || _deleted || _text.text == _saved) return;
    _saved = _text.text;
    await _study.saveNote(widget.verseId, _text.text);
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
      title: 'Delete this note?',
      message: 'It cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _deleted = true;
    _debounce?.cancel();
    await _study.deleteNote(widget.verseId);
    if (mounted) context.pop();
  }

  void _openJournal() {
    final allowed = canUse(
      PremiumFeature.journal,
      ref.read(entitlementProvider),
    );
    if (!allowed) {
      openPaywall(context, reason: PremiumFeature.journal);
      return;
    }
    context.push(
      '/journal-edit?verse=${Uri.encodeQueryComponent(widget.verseId)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final entry = ref.watch(entryProvider(widget.verseId)).value;
    final lang = ref.watch(languageProvider);
    final remaining = StudyLimits.noteMaxChars - _text.text.length;

    return Scaffold(
      appBar: AppBar(
        leading: LucideBackButton(onPressed: () => context.pop()),
        title: Text(entry == null ? 'Note' : 'Note · ${entry.label}'),
        actions: [
          IconButton(
            tooltip: 'Write in your journal',
            onPressed: _openJournal,
            icon: const Icon(LucideIcons.book_heart),
          ),
          if (_saved.trim().isNotEmpty)
            IconButton(
              tooltip: 'Delete note',
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
              if (entry != null)
                Container(
                  padding: const EdgeInsets.all(Space.s16),
                  decoration: BoxDecoration(
                    color: c.surfaceSoft,
                    borderRadius: BorderRadius.circular(Radii.input),
                  ),
                  child: Text(
                    entry.translation(lang),
                    style: readingStyles(
                      context,
                      ref,
                    ).translation(lang).copyWith(color: c.textSecondary),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: Space.s16),
              if (!_loaded)
                const SizedBox(height: Touch.minTarget)
              else
                TextField(
                  controller: _text,
                  autofocus: _text.text.isEmpty,
                  maxLines: null,
                  minLines: 8,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(StudyLimits.noteMaxChars),
                  ],
                  style: readingStyles(context, ref).translation('en'),
                  decoration: InputDecoration(
                    hintText: 'What does this verse say to you?',
                    hintStyle: ui.body(size: 16, color: c.textTertiary),
                    border: InputBorder.none,
                  ),
                ),
              if (remaining <= StudyLimits.counterWithin)
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      '$remaining characters left',
                      style: ui.body(size: 13, color: c.textTertiary),
                    ),
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
