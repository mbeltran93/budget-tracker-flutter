import 'package:flutter/foundation.dart';

import '../data/api_exception.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_summary.dart';

/// Holds the dashboard's `GET /api/dashboard/summary` data (total spent this
/// month + per-category progress) plus its own loading/error flags, so
/// [DashboardScreen] stays a thin, mockable consumer.
class DashboardState extends ChangeNotifier {
  DashboardState({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository;

  final DashboardRepository _dashboardRepository;

  DashboardSummary? summary;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      summary = await _dashboardRepository.getSummary();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Could not load the dashboard: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
