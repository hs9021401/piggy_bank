import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

class Category extends Equatable {
  final String id;
  final String name;
  final String icon;
  final int color;
  final TransactionType type;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    TransactionType? type,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.index,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as int,
      type: TransactionType.values[map['type'] as int],
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, type];
}
