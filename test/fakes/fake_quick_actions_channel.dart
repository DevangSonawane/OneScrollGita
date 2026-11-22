import 'dart:async';

import 'package:versescroll/data/platform/quick_actions_channel.dart';

/// Stands in for the iOS side of Home Screen Quick Actions.
class FakeQuickActionsChannel implements QuickActionsChannel {
  FakeQuickActionsChannel({this.initial});

  /// The shortcut that "launched" the app, if any.
  String? initial;
  final _actions = StreamController<String>.broadcast();

  /// Simulates choosing a shortcut while the app runs.
  void choose(String type) => _actions.add(type);

  @override
  Stream<String> get actions => _actions.stream;

  @override
  Future<String?> takeInitialAction() async {
    final v = initial;
    initial = null;
    return v;
  }
}
