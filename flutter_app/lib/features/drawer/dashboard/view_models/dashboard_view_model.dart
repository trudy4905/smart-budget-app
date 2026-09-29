import 'package:flutter/material.dart';
import 'package:flutter_app/core/providers/app_state.dart';

class DashboardViewModel extends ChangeNotifier {
  final AppState _appState;

  DashboardViewModel(this._appState) {
    _appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    notifyListeners();
  }

  Map<String, int> getMonthlySummary(int year, int month) {
    return _appState.getMonthlySummary(year, month);
  }

  DashboardSummary getDashboardSummary(int year, int month) {
    return _appState.getDashboardSummary(year, month);
  }
}
