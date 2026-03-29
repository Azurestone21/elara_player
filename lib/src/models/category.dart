import 'package:flutter/foundation.dart';
import 'media_item.dart';

@immutable
class Category {
  final String id;
  final String name;
  final MediaType type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  Category copyWith({
    String? id,
    String? name,
    MediaType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type)';
  }
}
