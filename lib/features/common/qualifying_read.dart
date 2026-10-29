import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/streak_providers.dart';

/// Counts a qualifying read of [verseId] once it has been on screen, with
/// the app in the foreground, for [dwell] (PRD_v2 section 4, [ReadRule]).
///
/// The timer restarts when [verseId] changes and pauses while the app is in
/// the background, the route is covered or the tab is hidden.
class QualifyingRead extends ConsumerStatefulWidget {
  const QualifyingRead({
    super.key,
    required this.verseId,
    required this.dwell,
    required this.child,
  });

  final String? verseId;
  final Duration dwell;
  final Widget child;

  @override
  ConsumerState<QualifyingRead> createState() => _QualifyingReadState();
}

class _QualifyingReadState extends ConsumerState<QualifyingRead>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (visible != _visible || _timer == null) {
      _visible = visible;
      _restart();
    }
  }

  @override
  void didUpdateWidget(QualifyingRead old) {
    super.didUpdateWidget(old);
    if (old.verseId != widget.verseId) _restart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    state == AppLifecycleState.resumed ? _restart() : _timer?.cancel();
  }

  void _restart() {
    _timer?.cancel();
    final id = widget.verseId;
    final resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (id == null || !_visible || !resumed) return;
    _timer = Timer(widget.dwell, () {
      if (mounted) ref.read(readTrackerProvider.notifier).qualify(id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
