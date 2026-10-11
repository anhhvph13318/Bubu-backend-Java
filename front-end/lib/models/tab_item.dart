import 'package:flutter/material.dart';

class TabItem {
  final IconData icon;
  final String label;
  final String module;
  final Widget page;

  const TabItem({
    required this.icon,
    required this.label,
    required this.module,
    required this.page,
  });
}
