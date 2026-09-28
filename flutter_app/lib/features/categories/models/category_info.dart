import 'package:flutter/material.dart';

class CategoryInfo {
  final String name;
  final String emoji;
  final Color color;
  final String type; // 'expense' or 'income'
  const CategoryInfo({required this.name, required this.emoji, required this.color, required this.type});

  Map<String, dynamic> toJson() => {
    'name': name,
    'emoji': emoji,
    'color': color.value,
    'type': type,
  };

  factory CategoryInfo.fromJson(Map<String, dynamic> json) => CategoryInfo(
    name: json['name'],
    emoji: json['emoji'],
    color: Color(json['color']),
    type: json['type'],
  );
}

const kExpenseCategories = [
  CategoryInfo(name: '식당', emoji: '🍽️', color: Color(0xFFE11D48), type: 'expense'),
  CategoryInfo(name: '장보기', emoji: '🛒', color: Color(0xFFFB923C), type: 'expense'),
  CategoryInfo(name: '카페/디저트', emoji: '☕', color: Color(0xFF9333EA), type: 'expense'),
  CategoryInfo(name: '교통/차량', emoji: '🚌', color: Color(0xFF06B6D4), type: 'expense'),
  CategoryInfo(name: '문화/쇼핑', emoji: '🎬', color: Color(0xFFEC4899), type: 'expense'),
  CategoryInfo(name: '적금/저축', emoji: '💰', color: Color(0xFF2563EB), type: 'expense'),
  CategoryInfo(name: '기타', emoji: '📌', color: Color(0xFF94A3B8), type: 'expense'),
];

const kIncomeCategories = [
  CategoryInfo(name: '수입/월급', emoji: '💵', color: Color(0xFF059669), type: 'income'),
  CategoryInfo(name: '용돈', emoji: '🎁', color: Color(0xFFF59E0B), type: 'income'),
  CategoryInfo(name: '부수입', emoji: '📈', color: Color(0xFF4F46E5), type: 'income'),
  CategoryInfo(name: '상여금', emoji: '🏆', color: Color(0xFF7C3AED), type: 'income'),
];



// ============================================================
