/// An expense, matching `ExpenseResponse` from the backend:
/// `{"id":1,"categoryId":1,"categoryName":"Comida","amount":12.50,
///   "description":"Almuerzo","date":"2026-09-30"}`.
///
/// [date] is stored as a plain `DateTime` at midnight (no time component is
/// sent by the API), serialized back to the `YYYY-MM-DD` string the backend
/// expects.
class Expense {
  const Expense({
    this.id,
    required this.categoryId,
    this.categoryName,
    required this.amount,
    required this.description,
    required this.date,
  });

  final int? id;
  final int categoryId;
  final String? categoryName;
  final double amount;
  final String description;
  final DateTime date;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as int?,
        categoryId: json['categoryId'] as int,
        categoryName: json['categoryName'] as String?,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
      );

  /// Body shape for `POST /api/expenses` and `PUT /api/expenses/{id}`.
  Map<String, dynamic> toRequestJson() => {
        'categoryId': categoryId,
        'amount': amount,
        'description': description,
        'date': formatDate(date),
      };

  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Expense copyWith({
    int? id,
    int? categoryId,
    String? categoryName,
    double? amount,
    String? description,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }
}
