import '../models/category.dart';
import 'api_client.dart';

/// Wraps `GET /api/categories`.
class CategoryRepository {
  CategoryRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Category>> getCategories() async {
    final response = await _apiClient.get('/api/categories');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
