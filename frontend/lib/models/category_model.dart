import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String? userId;
  final String name;
  final String type; // 'INCOME' or 'EXPENSE'
  final String colorHex;
  final String icon;
  final bool isSystem;

  CategoryModel({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    required this.colorHex,
    required this.icon,
    required this.isSystem,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      colorHex: json['color'] ?? '#3B82F6',
      icon: json['icon'] ?? 'category',
      isSystem: json['is_system'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'color': colorHex,
      'icon': icon,
      'is_system': isSystem,
    };
  }

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF3B82F6);
  }

  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'payments':
      case 'money':
      case 'salary':
        return Icons.account_balance_wallet_rounded;
      case 'laptop':
      case 'freelance':
        return Icons.laptop_mac_rounded;
      case 'business':
      case 'store':
        return Icons.storefront_rounded;
      case 'trending_up':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;
      case 'directions_car':
      case 'transportation':
        return Icons.directions_car_rounded;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'local_hospital':
      case 'health':
        return Icons.medical_services_rounded;
      case 'school':
      case 'education':
        return Icons.school_rounded;
      case 'receipt_long':
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'movie':
      case 'entertainment':
        return Icons.movie_filter_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

