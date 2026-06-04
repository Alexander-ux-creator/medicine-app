import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../helpers/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final dbHelper = DatabaseHelper();

  Future<void> _exportData() async {
    try {
      final data = await dbHelper.exportDatabase();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'medicine_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Данные экспортированы'),
            backgroundColor: Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Импорт временно недоступен'),
            backgroundColor: Color(0xFFF39C12),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚠️ Внимание!'),
        content: const Text('Это удалит ВСЕ лекарства и категории. Действие необратимо!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Удалить всё'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = await dbHelper.database;
        await db.delete('medicines');
        await db.delete('categories');
        await dbHelper.insertDefaultCategories(db);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ Все данные удалены'),
              backgroundColor: Color(0xFFE74C3C),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Настройки'),
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('🌙 Тёмная тема'),
              subtitle: Text(themeProvider.isDarkMode ? 'Включена' : 'Выключена'),
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('🌍 Язык'),
              subtitle: Text(languageProvider.locale.languageCode == 'ru' ? 'Русский' : 'English'),
              trailing: const Icon(Icons.language),
              onTap: () => _showLanguageDialog(languageProvider),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('📁 Категории'),
              subtitle: const Text('Управление группами лекарств'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/categories'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('💾 Экспорт данных'),
                  subtitle: const Text('Сохранить в файл'),
                  trailing: const Icon(Icons.upload),
                  onTap: _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('📥 Импорт данных'),
                  subtitle: const Text('Восстановить из файла'),
                  trailing: const Icon(Icons.download),
                  onTap: _importData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('🗑️ Удалить все данные'),
              subtitle: const Text('Сбросить приложение'),
              trailing: const Icon(Icons.delete, color: Colors.red),
              onTap: _clearAllData,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('ℹ️ О приложении'),
              subtitle: const Text('Версия 2.0.0'),
              trailing: const Icon(Icons.info_outline),
              onTap: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('ℹ️ О приложении'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.medication, size: 64, color: Color(0xFF2ECC71)),
                      const SizedBox(height: 16),
                      const Text('Моя Аптечка', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Версия 2.0.0', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      const Text('Приложение для учёта лекарств\nв домашней аптечке'),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(LanguageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🌍 Выберите язык'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇷🇺', style: TextStyle(fontSize: 24)),
              title: const Text('Русский'),
              selected: provider.locale.languageCode == 'ru',
              onTap: () {
                provider.setLanguage('ru');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              selected: provider.locale.languageCode == 'en',
              onTap: () {
                provider.setLanguage('en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}