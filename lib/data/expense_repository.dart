import '../models/expense.dart';
import 'api_client.dart';

/// Wraps the expense CRUD endpoints: `GET/POST /api/expenses` and
/// `PUT/DELETE /api/expenses/{id}`.
class ExpenseRepository {
  ExpenseRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Expense>> getExpenses() async {
    final response = await _apiClient.get('/api/expenses');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await _apiClient.post(
      '/api/expenses',
      data: expense.toRequestJson(),
    );
    return Expense.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Expense> updateExpense(int id, Expense expense) async {
    final response = await _apiClient.put(
      '/api/expenses/$id',
      data: expense.toRequestJson(),
    );
    return Expense.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteExpense(int id) async {
    await _apiClient.delete('/api/expenses/$id');
  }
}
