import 'package:flutter/material.dart';

typedef FormulaBuilder = Widget Function(BuildContext context);

class FormulaMeta {
  final String id;
  final String titleKey;
  final String categoryId;
  final IconData? icon;
  final String? assetPath;
  final List<String> tags;
  final bool enabled;
  final FormulaBuilder builder;

  const FormulaMeta({
    required this.id,
    required this.titleKey,
    required this.categoryId,
    required this.builder,
    this.icon,
    this.assetPath,
    this.tags = const [],
    this.enabled = true,
  });
}
