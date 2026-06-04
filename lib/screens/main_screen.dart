import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/medicine.dart';
import '../models/category.dart';
import 'edit_medicine_screen.dart';
import 'categories_screen.dart';  // ✅ УБРАНО 'show CategoriesScreen'
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'barcode_scanner_screen.dart';
import 'onboarding_screen.dart';  // ✅ УБРАНО 'show OnboardingScreen'
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final dbHelper = DatabaseHelper();
  List<Medicine> medicines = [];
  List<Category> categories = [];
  List<Medicine> filteredMedicines = [];
  final TextEditingController _searchController = TextEditingController();
  
  MedicineFilter _currentFilter = MedicineFilter.all;
  final MedicineSort _currentSort = MedicineSort.expiry;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_complete') ?? false;
    if (!completed && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _loadData() async {
    final meds = await dbHelper.getMedicines();
    final cats = await dbHelper.getCategories();
    if (mounted) {
      setState(() {
        medicines = meds;
        categories = cats;
        _applyFiltersAndSort();
      });
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      _applyFiltersAndSort();
    }
  }

  void _applyFiltersAndSort() {
    List<Medicine> result = List.from(medicines);
    
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((med) {
        final name = med.name.toLowerCase();
        final desc = (med.description ?? '').toLowerCase();
        return name.contains(query) || desc.contains(query);
      }).toList();
    }

    if (_selectedCategoryId != null) {
      result = result.where((med) => med.categoryId == _selectedCategoryId).toList();
    }
    
    result = result.where((med) {
      final daysLeft = med.expiryDate.difference(DateTime.now()).inDays;
      switch (_currentFilter) {
        case MedicineFilter.all: return true;
        case MedicineFilter.good: return daysLeft > 3;
        case MedicineFilter.warning: return daysLeft >= 0 && daysLeft <= 3;
        case MedicineFilter.expired: return daysLeft < 0;
      }
    }).toList();
    
    switch (_currentSort) {
      case MedicineSort.name:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case MedicineSort.expiry:
        result.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case MedicineSort.status:
        result.sort((a, b) {
          final daysA = a.expiryDate.difference(DateTime.now()).inDays;
          final daysB = b.expiryDate.difference(DateTime.now()).inDays;
          return daysA.compareTo(daysB);
        });
        break;
    }
    
    if (mounted) {
      setState(() {
        filteredMedicines = result;
      });
    }
  }

  void _changeFilter(MedicineFilter filter) {
    setState(() => _currentFilter = filter);
    _applyFiltersAndSort();
  }

  Map<MedicineFilter, int> _getCounts() {
    final now = DateTime.now();
    return {
      MedicineFilter.all: medicines.length,
      MedicineFilter.good: medicines.where((m) => m.expiryDate.difference(now).inDays > 3).length,
      MedicineFilter.warning: medicines.where((m) {
        final days = m.expiryDate.difference(now).inDays;
        return days >= 0 && days <= 3;
      }).length,
      MedicineFilter.expired: medicines.where((m) => m.expiryDate.isBefore(now)).length,
    };
  }

  Color _getCardColor(int daysLeft) {
    if (daysLeft < 0) return const Color(0xFFE74C3C);
    if (daysLeft <= 3) return const Color(0xFFF39C12);
    return const Color(0xFF2ECC71);
  }

  String _getStatusText(int daysLeft) {
    if (daysLeft < 0) return 'Просрочено';
    if (daysLeft <= 3) return 'Истекает скоро';
    return 'В норме';
  }

  IconData _getStatusIcon(int daysLeft) {
    if (daysLeft < 0) return Icons.error_outline;
    if (daysLeft <= 3) return Icons.warning_amber_rounded;
    return Icons.check_circle_outline;
  }

  void _confirmDelete(Medicine med) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить лекарство?'),
        content: Text('Вы уверены, что хотите удалить "${med.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              if (med.photoPath != null && med.photoPath!.isNotEmpty) {
                try {
                  final file = File(med.photoPath!);
                  if (await file.exists()) await file.delete();
                } catch (_) {}
              }
              await dbHelper.delete(med.id!);
              await _loadData();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🗑️ Лекарство удалено'), backgroundColor: Color(0xFFE74C3C), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showMedicineDetails(Medicine med, int daysLeft) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                if (med.photoPath != null && med.photoPath!.isNotEmpty)
                  Center(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(med.photoPath!), height: 200, width: double.infinity, fit: BoxFit.cover))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _getCardColor(daysLeft).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.medication, color: _getCardColor(daysLeft), size: 32)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(med.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(_getStatusText(daysLeft), style: TextStyle(color: _getCardColor(daysLeft), fontWeight: FontWeight.w500)),
                  ])),
                ]),
                const SizedBox(height: 24),
                _buildDetailRow(Icons.description, 'Описание', med.description ?? 'Нет описания'),
                _buildDetailRow(Icons.calendar_today, 'Срок годности', DateFormat('dd.MM.yyyy').format(med.expiryDate)),
                _buildDetailRow(Icons.timer, 'Осталось дней', daysLeft < 0 ? '${daysLeft.abs()} дней назад' : '$daysLeft дней'),
                if (med.dosage != null) _buildDetailRow(Icons.medication, 'Дозировка', med.dosage!),
                if (med.frequency != null) _buildDetailRow(Icons.access_time, 'Частота', med.frequency!),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditMedicineScreen(medicine: med, categories: categories)),
                          );
                          if (result == true && mounted) await _loadData();
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Редактировать'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71), foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDelete(med),
                        icon: const Icon(Icons.delete),
                        label: const Text('Удалить'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counts = _getCounts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏥 Моя Аптечка'),
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner), tooltip: 'Сканер', onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()));
            if (result != null && result is Map && mounted) {
              final added = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditMedicineScreen(
                categories: categories,
              )));
              if (added == true && mounted) await _loadData();
            }
          }),
          IconButton(icon: const Icon(Icons.bar_chart), tooltip: 'Статистика', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen(medicines: medicines, categories: categories)))),
          IconButton(icon: const Icon(Icons.settings), tooltip: 'Настройки', onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            if (result == true && mounted) await _loadData();
          }),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '🔍 Поиск лекарств...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(label: Text('Все (${counts[MedicineFilter.all]})'), selected: _currentFilter == MedicineFilter.all, onSelected: (selected) => _changeFilter(MedicineFilter.all)),
                const SizedBox(width: 8),
                FilterChip(label: Text('В норме (${counts[MedicineFilter.good]})'), selected: _currentFilter == MedicineFilter.good, onSelected: (selected) => _changeFilter(MedicineFilter.good)),
                const SizedBox(width: 8),
                FilterChip(label: Text('Истекают (${counts[MedicineFilter.warning]})'), selected: _currentFilter == MedicineFilter.warning, onSelected: (selected) => _changeFilter(MedicineFilter.warning)),
                const SizedBox(width: 8),
                FilterChip(label: Text('Просрочено (${counts[MedicineFilter.expired]})'), selected: _currentFilter == MedicineFilter.expired, onSelected: (selected) => _changeFilter(MedicineFilter.expired)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredMedicines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_searchController.text.isEmpty ? Icons.medication_outlined : Icons.search_off, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(_searchController.text.isEmpty ? 'Аптечка пуста\nДобавьте первое лекарство' : 'Ничего не найдено', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredMedicines.length,
                    itemBuilder: (context, index) {
                      final med = filteredMedicines[index];
                      final daysLeft = med.expiryDate.difference(DateTime.now()).inDays;
                      final statusColor = _getCardColor(daysLeft);
                      final category = categories.firstWhere((c) => c.id == med.categoryId, orElse: () => Category(name: '', icon: '', color: 0));
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: med.photoPath != null && med.photoPath!.isNotEmpty
                                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(med.photoPath!), fit: BoxFit.cover))
                                : Icon(Icons.medication, color: statusColor, size: 28),
                          ),
                          title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (category.name.isNotEmpty) Text('${category.icon} ${category.name}', style: TextStyle(fontSize: 12, color: Color(category.color))),
                              Text(med.description ?? 'Нет описания', maxLines: 1, overflow: TextOverflow.ellipsis),
                              Row(children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(DateFormat('dd.MM.yyyy').format(med.expiryDate), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                const SizedBox(width: 8),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(daysLeft < 0 ? '${daysLeft.abs()} дн.' : '$daysLeft дн.', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12))),
                              ]),
                            ],
                          ),
                          trailing: Icon(_getStatusIcon(daysLeft), color: statusColor),
                          onTap: () => _showMedicineDetails(med, daysLeft),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'categories',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2ECC71),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CategoriesScreen())),
            child: const Icon(Icons.folder),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditMedicineScreen(categories: categories)));
              if (result == true && mounted) await _loadData();
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
            backgroundColor: const Color(0xFF2ECC71),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

enum MedicineFilter { all, good, warning, expired }
enum MedicineSort { name, expiry, status }