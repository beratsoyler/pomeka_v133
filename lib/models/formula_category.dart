import 'package:flutter/material.dart';

class FormulaCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color? color;

  const FormulaCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.color,
  });
}
