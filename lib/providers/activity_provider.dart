import 'package:flutter/foundation.dart';
import 'package:pracpro/models/activity_progress.dart';
import 'package:pracpro/services/activity_service.dart';

class ActivityProvider with ChangeNotifier {
  final ActivityService _service = ActivityService();
  List<ActivityProgress> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ActivityProgress> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? v) {
    _error = v;
    notifyListeners();
  }

  Future<void> loadActivity(String classroomId) async {
    _setLoading(true);
    try {
      final result = await _service.getActivityProgress(classroomId);
      _items = result;
      _setError(null);
    } catch (e, stack) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
