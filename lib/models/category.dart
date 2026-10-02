/// A spending category with its configured monthly limit.
///
/// Mirrors `GET /api/categories`:
/// `{"id": 1, "name": "Comida", "monthlyLimit": 500.00}`.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.monthlyLimit,
  });

  final int id;
  final String name;
  final double monthlyLimit;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'monthlyLimit': monthlyLimit,
      };
}
