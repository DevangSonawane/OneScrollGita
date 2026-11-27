import 'package:versescroll/data/widgets/home_widget_repository.dart';

/// Records what the app would write for the home-screen widgets.
class FakeHomeWidgetRepository extends HomeWidgetRepository {
  final listen = <Map<String, Object>>[];

  @override
  Future<String?> dailyStamp() async => null;

  @override
  Future<void> saveDaily(List<Map<String, String>> items, String stamp) async {}

  @override
  Future<void> saveHistory(List<Map<String, String>> items) async {}

  @override
  Future<void> saveListen(Map<String, Object> state) async => listen.add(state);
}
