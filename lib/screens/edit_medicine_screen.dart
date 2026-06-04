import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../models/medicine.dart';
import '../models/category.dart';
import '../helpers/database_helper.dart';
import '../services/api_service.dart';

class EditMedicineScreen extends StatefulWidget {
  final Medicine? medicine;
  final List<Category> categories;

  const EditMedicineScreen({super.key, this.medicine, required this.categories});

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _dosageController;
  late TextEditingController _frequencyController;
  late DateTime _selectedDate;
  late int? _selectedCategoryId;
  late String? _photoPath;
  late bool _hasReminder;
  late TimeOfDay? _reminderTime;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _descController = TextEditingController(text: widget.medicine?.description ?? '');
    _dosageController = TextEditingController(text: widget.medicine?.dosage ?? '');
    _frequencyController = TextEditingController(text: widget.medicine?.frequency ?? '');
    _selectedDate = widget.medicine?.expiryDate ?? DateTime.now().add(const Duration(days: 365));
    _selectedCategoryId = widget.medicine?.categoryId;
    _photoPath = widget.medicine?.photoPath;
    _hasReminder = widget.medicine?.hasReminder ?? false;
    _reminderTime = widget.medicine?.reminderTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<String?> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (photo != null) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(photo.path)}';
        final savedFile = File('${dir.path}/medicine_photos/$fileName');
        await savedFile.parent.create(recursive: true);
        await File(photo.path).copy(savedFile.path);
        return savedFile.path;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medicine != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '✏️ Редактировать' : '💊 Добавить'),
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Фото
            GestureDetector(
              onTap: () => _showPhotoOptions(),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _photoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_photoPath!), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('📷 Добавить фото', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Название - ✅ БЕЗ параметра value (используем только controller)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название препарата *',
                prefixIcon: Icon(Icons.medication_outlined),
              ),
              validator: (val) => val?.isEmpty ?? true ? 'Введите название' : null,
              onChanged: (val) async {
                if (val.length > 3 && !isEdit) {
                  final foundDesc = await ApiService.searchDescription(val);
                  if (foundDesc != null && _descController.text.isEmpty && mounted) {
                    _descController.text = foundDesc;
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // Описание
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Категория
            DropdownButtonFormField<int?>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Категория',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Без категории')),
                ...widget.categories.map((cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Text('${cat.icon} ${cat.name}'),
                )),
              ],
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(height: 16),

            // Дозировка
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Дозировка',
                prefixIcon: Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 16),

            // Частота
            TextFormField(
              controller: _frequencyController,
              decoration: const InputDecoration(
                labelText: 'Частота приёма',
                prefixIcon: Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 16),

            // Срок годности
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF2ECC71)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Срок: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Напоминание
            SwitchListTile(
              title: const Text('🔔 Напоминание о сроке'),
              subtitle: Text(_hasReminder ? 'Включено' : 'Выключено'),
              value: _hasReminder,
              onChanged: (val) => setState(() => _hasReminder = val),
            ),

            if (_hasReminder) ...[
              ListTile(
                title: const Text('Время напоминания'),
                subtitle: Text(_reminderTime != null 
                    ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                    : 'Не выбрано'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime ?? TimeOfDay.now(),
                  );
                  if (time != null) setState(() => _reminderTime = time);
                },
              ),
            ],
            const SizedBox(height: 24),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isEdit ? 'Сохранить' : 'Добавить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('📷 Сделать фото'),
              onTap: () async {
                Navigator.pop(context);
                final path = await _pickImage(ImageSource.camera);
                if (path != null && mounted) setState(() => _photoPath = path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('🖼️ Из галереи'),
              onTap: () async {
                Navigator.pop(context);
                final path = await _pickImage(ImageSource.gallery);
                if (path != null && mounted) setState(() => _photoPath = path);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить фото', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final medicine = Medicine(
        id: widget.medicine?.id,
        name: _nameController.text,
        description: _descController.text.isEmpty ? null : _descController.text,
        expiryDate: _selectedDate,
        photoPath: _photoPath,
        categoryId: _selectedCategoryId,
        dosage: _dosageController.text.isEmpty ? null : _dosageController.text,
        frequency: _frequencyController.text.isEmpty ? null : _frequencyController.text,
        hasReminder: _hasReminder,
        reminderTime: _reminderTime,
      );

      final dbHelper = DatabaseHelper();
      if (widget.medicine != null) {
        await dbHelper.update(medicine);
      } else {
        await dbHelper.insert(medicine);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.medicine != null ? '✅ Обновлено' : '✅ Добавлено'),
            backgroundColor: const Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}