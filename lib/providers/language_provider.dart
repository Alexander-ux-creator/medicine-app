import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('ru');
  Locale get locale => _locale;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'ru';
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _locale = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    notifyListeners();
  }

  String t(String key) {
    return _translations[_locale.languageCode]?[key] ?? key;
  }

  final Map<String, Map<String, String>> _translations = {
    'ru': {
      'app_title': 'Моя Аптечка',
      'add_medicine': 'Добавить',
      'search': 'Поиск лекарств...',
      'all': 'Все',
      'good': 'В норме',
      'warning': 'Истекают',
      'expired': 'Просрочено',
      'stats': 'Статистика',
      'export_pdf': 'Экспорт PDF',
      'settings': 'Настройки',
      'dark_mode': 'Тёмная тема',
      'language': 'Язык',
      'categories': 'Категории',
      'edit': 'Редактировать',
      'delete': 'Удалить',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'name': 'Название',
      'description': 'Описание',
      'expiry_date': 'Срок годности',
      'category': 'Категория',
      'dosage': 'Дозировка',
      'frequency': 'Частота',
      'reminder': 'Напоминание',
      'photo': 'Фото',
      'take_photo': 'Сделать фото',
      'from_gallery': 'Из галереи',
      'delete_photo': 'Удалить',
      'edit_medicine': 'Редактировать',
      'backup_restore': 'Резервная копия',
      'export_data': 'Экспорт данных',
      'import_data': 'Импорт данных',
      'success': 'Успешно',
      'error': 'Ошибка',
      'confirm_delete': 'Подтвердите удаление',
      'are_you_sure': 'Вы уверены?',
    },
    'en': {
      'app_title': 'My Medicine Cabinet',
      'add_medicine': 'Add',
      'search': 'Search medicines...',
      'all': 'All',
      'good': 'Good',
      'warning': 'Expiring',
      'expired': 'Expired',
      'stats': 'Statistics',
      'export_pdf': 'Export PDF',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'categories': 'Categories',
      'edit': 'Edit',
      'delete': 'Delete',
      'save': 'Save',
      'cancel': 'Cancel',
      'name': 'Name',
      'description': 'Description',
      'expiry_date': 'Expiry Date',
      'category': 'Category',
      'dosage': 'Dosage',
      'frequency': 'Frequency',
      'reminder': 'Reminder',
      'photo': 'Photo',
      'take_photo': 'Take Photo',
      'from_gallery': 'From Gallery',
      'delete_photo': 'Delete',
      'edit_medicine': 'Edit Medicine',
      'backup_restore': 'Backup & Restore',
      'export_data': 'Export Data',
      'import_data': 'Import Data',
      'success': 'Success',
      'error': 'Error',
      'confirm_delete': 'Confirm Delete',
      'are_you_sure': 'Are you sure?',
    },
  };
}