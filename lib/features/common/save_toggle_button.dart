import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/library_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';

enum SaveKind { favourite, bookmark }

/// Favourite or bookmark toggle. Optimistic, with a 1.0 → 1.15 → 1.0 pulse.
class SaveToggleButton extends ConsumerStatefulWidget {
  const SaveToggleButton({super.key, required this.verseId, required this.kind});

  final String verseId;
  final SaveKind kind;

  @override
  ConsumerState<SaveToggleButton> createState() => _SaveToggleButtonState();
}

class _SaveToggleButtonState extends ConsumerState<SaveToggleButton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.savePulse,
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.15), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1), weight: 1),
  ]).animate(CurvedAnimation(parent: _pulse, curve: AppCurves.standard));

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    unawaited(HapticFeedback.lightImpact());
    if (!Motion.of(context).reduced) unawaited(_pulse.forward(from: 0));
    final library = ref.read(libraryControllerProvider.notifier);
    final ok = widget.kind == SaveKind.favourite
        ? await library.toggleFavourite(widget.verseId)
        : await library.toggleBookmark(widget.verseId);
    if (!ok && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = ref.watch(savedStateProvider(widget.verseId));
    final fav = widget.kind == SaveKind.favourite;
    final on = fav ? state.isFavourite : state.isBookmarked;
    final icon = fav
        ? (on ? Icons.favorite_rounded : Icons.favorite_border_rounded)
        : (on ? Icons.bookmark_rounded : Icons.bookmark_border_rounded);
    final label = fav
        ? (on ? 'Remove from favourites' : 'Add to favourites')
        : (on ? 'Remove bookmark' : 'Add bookmark');
    return Semantics(
      toggled: on,
      child: Pressable(
        onTap: _toggle,
        semanticLabel: label,
        child: SizedBox.square(
          dimension: Touch.minTarget,
          child: ScaleTransition(
            scale: _scale,
            child: AnimatedSwitcher(
              duration: Motion.of(context).savePulse,
              child: Icon(
                icon,
                key: ValueKey(on),
                size: IconSizes.regular,
                color: on ? c.accent : c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
