import 'package:flutter/material.dart';

class FormulaCategory {
  final String id;
  final String title;
  final IconData icon;
  final String? description;

  const FormulaCategory({
    required this.id,
    required this.title,
    required this.icon,
    this.description,
  });
}
