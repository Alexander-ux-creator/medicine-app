import 'package:flutter/material.dart';
import '../models/category.dart';
import '../helpers/database_helper.dart';

// ✅ КЛАСС НАЗЫВАЕТСЯ CategoriesScreen (не OnboardingScreen!)
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final dbHelper = DatabaseHelper();
  List<Category> categories = [];
  final _nameController = TextEditingController();
  String _selectedIcon = '📦';
  Color _selectedColor = const Color(0xFF2ECC71);

  final List<String> _icons = ['📦', '💊', '🧴', '💧', '🍊', '🦠', '🏥', '💉', '🩹', '', '🧬', '🔬'];
  final List<Color> _colors = [
    const Color(0xFF2ECC71), const Color(0xFFF39C12), const Color(0xFF3498DB),
    const Color(0xFFE67E22), const Color(0xFFE74C3C), const Color(0xFF9B59B6),
    const Color(0xFF1ABC9C), const Color(0xFF34495E), const Color(0xFFE84393),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final data = await dbHelper.getCategories();
    setState(() => categories = data);
  }

  void _showAddDialog() {
    _nameController.clear();
    _selectedIcon = '📦';
    _selectedColor = const Color(0xFF2ECC71);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('📁 Новая категория'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('Иконка'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _icons.map((icon) => GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedIcon == icon ? const Color(0xFF2ECC71) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Цвет'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((color) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                await dbHelper.insertCategory(Category(
                  name: _nameController.text,
                  icon: _selectedIcon,
                  color: _selectedColor.value,
                ));
                await _loadCategories();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Category category) {
    _nameController.text = category.name;
    _selectedIcon = category.icon;
    _selectedColor = Color(category.color);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✏️ Редактировать'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 16),
              const Text('Иконка'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _icons.map((icon) => GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedIcon == icon ? const Color(0xFF2ECC71) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Цвет'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((color) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                await dbHelper.updateCategory(category.copyWith(
                  name: _nameController.text,
                  icon: _selectedIcon,
                  color: _selectedColor.value,
                ));
                await _loadCategories();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text('Вы уверены, что хотите удалить "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await dbHelper.deleteCategory(category.id!);
              await _loadCategories();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📁 Категории'),
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
      ),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Нет категорий', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Нажмите + чтобы добавить', style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(cat.color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 24))),
                    ),
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF2ECC71)),
                          onPressed: () => _showEditDialog(cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(cat),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Создать'),
        backgroundColor: const Color(0xFF2ECC71),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}