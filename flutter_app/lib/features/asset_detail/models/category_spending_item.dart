import 'package:flutter/material.dart';

class CategorySpendingItem {
  final String category;
  final String emoji;
  final Color color;
  final int amount;
  final double percentage; // 0.0 ~ 1.0

  const CategorySpendingItem({
    required this.category,
    required this.emoji,
    required this.color,
    required this.amount,
    required this.percentage,
  });
}
