import 'package:flutter/material.dart';

class Formula {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final List<String> tags;
  final IconData? icon;
  final DateTime? lastUsedAt;
  final bool isFavorite;

  const Formula({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.tags,
    this.icon,
    this.lastUsedAt,
    this.isFavorite = false,
  });
}
