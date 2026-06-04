import 'package:flutter/material.dart';

class Medicine {
  final int? id;
  final String name;
  final String? description;
  final DateTime expiryDate;
  final String? photoPath;
  final int? categoryId;
  final String? dosage;
  final String? frequency;
  final bool hasReminder;
  final TimeOfDay? reminderTime;

  Medicine({
    this.id,
    required this.name,
    this.description,
    required this.expiryDate,
    this.photoPath,
    this.categoryId,
    this.dosage,
    this.frequency,
    this.hasReminder = false,
    this.reminderTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'expiryDate': expiryDate.toIso8601String(),
      'photoPath': photoPath,
      'categoryId': categoryId,
      'dosage': dosage,
      'frequency': frequency,
      'hasReminder': hasReminder ? 1 : 0,
      'reminderTime': reminderTime != null 
          ? '${reminderTime!.hour}:${reminderTime!.minute}' 
          : null,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    TimeOfDay? reminderTime;
    if (map['reminderTime'] != null) {
      final parts = map['reminderTime'].split(':');
      reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return Medicine(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      expiryDate: DateTime.parse(map['expiryDate']),
      photoPath: map['photoPath'],
      categoryId: map['categoryId'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      hasReminder: map['hasReminder'] == 1,
      reminderTime: reminderTime,
    );
  }

  Medicine copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? expiryDate,
    String? photoPath,
    int? categoryId,
    String? dosage,
    String? frequency,
    bool? hasReminder,
    TimeOfDay? reminderTime,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      expiryDate: expiryDate ?? this.expiryDate,
      photoPath: photoPath ?? this.photoPath,
      categoryId: categoryId ?? this.categoryId,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isExpired => daysUntilExpiry < 0;
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days >= 0 && days <= 3;
  }

  String get statusText {
    if (isExpired) return 'Просрочено';
    if (isExpiringSoon) return 'Истекает скоро';
    return 'В норме';
  }
}