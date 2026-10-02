import '../models/dashboard_summary.dart';
import 'api_client.dart';

/// Wraps `GET /api/dashboard/summary`.
class DashboardRepository {
  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<DashboardSummary> getSummary() async {
    final response = await _apiClient.get('/api/dashboard/summary');
    return DashboardSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
