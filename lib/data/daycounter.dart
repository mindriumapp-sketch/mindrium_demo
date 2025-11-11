import 'dart:async';
import 'package:flutter/material.dart';

class UserDayCounter extends ChangeNotifier {
  DateTime? _createdAt;
  Timer? _timer;

  void setCreatedAt(DateTime date) {
    _createdAt = date;
    _startDailyTimer();
    notifyListeners();
  }

  bool get isUserLoaded => _createdAt != null;

  int get daysSinceJoin {
    if (_createdAt == null) return 0;
    return DateTime.now().difference(_createdAt!).inDays + 1;
  }

  int getWeekNumberFromJoin(DateTime targetDate) {
    if (_createdAt == null) return 0;

    final daysDiff = targetDate.difference(_createdAt!).inDays;
    return daysDiff < 0 ? 0 : (daysDiff ~/ 7) + 1;
  }

  void _startDailyTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 24), (_) {
      notifyListeners(); // 하루마다 갱신
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

