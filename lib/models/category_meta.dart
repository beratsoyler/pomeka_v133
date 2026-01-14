import 'package:flutter/material.dart';

class CategoryMeta {
  final String id;
  final String titleKey;
  final IconData icon;
  final int sortOrder;

  const CategoryMeta({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.sortOrder,
  });
}
