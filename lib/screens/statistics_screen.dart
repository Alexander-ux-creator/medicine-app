import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';
import '../models/category.dart';

class StatisticsScreen extends StatefulWidget {
  final List<Medicine> medicines;
  final List<Category> categories;

  const StatisticsScreen({super.key, required this.medicines, required this.categories});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Статистика'),
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: '📈 Обзор'),
              Tab(text: '📅 По срокам'),
              Tab(text: '📁 По категориям'),
            ],
            onTap: (index) => setState(() => _selectedTabIndex = index),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildOverviewTab(),
                _buildExpiryTab(),
                _buildCategoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final now = DateTime.now();
    final total = widget.medicines.length;
    final good = widget.medicines.where((m) => m.expiryDate.difference(now).inDays > 3).length;
    final warning = widget.medicines.where((m) {
      final days = m.expiryDate.difference(now).inDays;
      return days >= 0 && days <= 3;
    }).length;
    final expired = widget.medicines.where((m) => m.expiryDate.isBefore(now)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard('Всего лекарств', total.toString(), Colors.blue),
          const SizedBox(height: 12),
          _buildStatCard('В норме', good.toString(), const Color(0xFF2ECC71)),
          const SizedBox(height: 12),
          _buildStatCard('Истекают', warning.toString(), const Color(0xFFF39C12)),
          const SizedBox(height: 12),
          _buildStatCard('Просрочено', expired.toString(), const Color(0xFFE74C3C)),
          const SizedBox(height: 24),
          _buildPieChart(good, warning, expired),
          const SizedBox(height: 24),
          if (expired > 0) _buildExpiredList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(int good, int warning, int expired) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Распределение по статусу', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: good.toDouble(), color: const Color(0xFF2ECC71), title: 'В норме', radius: 80),
                    PieChartSectionData(value: warning.toDouble(), color: const Color(0xFFF39C12), title: 'Истекают', radius: 80),
                    PieChartSectionData(value: expired.toDouble(), color: const Color(0xFFE74C3C), title: 'Просрочено', radius: 80),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend('В норме', const Color(0xFF2ECC71)),
                const SizedBox(width: 16),
                _buildLegend('Истекают', const Color(0xFFF39C12)),
                const SizedBox(width: 16),
                _buildLegend('Просрочено', const Color(0xFFE74C3C)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildExpiredList() {
    final now = DateTime.now();
    final expired = widget.medicines.where((m) => m.expiryDate.isBefore(now)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Просроченные лекарства', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE74C3C))),
            const SizedBox(height: 12),
            ...expired.map((med) => ListTile(
              leading: const Icon(Icons.error, color: Color(0xFFE74C3C)),
              title: Text(med.name),
              subtitle: Text('Истёк: ${DateFormat('dd.MM.yyyy').format(med.expiryDate)}'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryTab() {
    final now = DateTime.now();
    final thisMonth = widget.medicines.where((m) => 
      m.expiryDate.month == now.month && m.expiryDate.year == now.year
    ).length;
    final nextMonth = widget.medicines.where((m) {
      final next = now.month == 12 ? DateTime(now.year + 1, 1) : DateTime(now.year, now.month + 1);
      return m.expiryDate.month == next.month && m.expiryDate.year == next.year;
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard('Истекают в этом месяце', thisMonth.toString(), const Color(0xFFF39C12)),
          const SizedBox(height: 12),
          _buildStatCard('Истекают в следующем месяце', nextMonth.toString(), const Color(0xFF3498DB)),
          const SizedBox(height: 24),
          _buildExpiryBarChart(),
        ],
      ),
    );
  }

  Widget _buildExpiryBarChart() {
    final Map<String, int> monthData = {};
    
    for (var med in widget.medicines) {
      final key = '${med.expiryDate.month}/${med.expiryDate.year.toString().substring(2)}';
      monthData[key] = (monthData[key] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Лекарства по месяцам', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: monthData.entries.map((e) => BarChartGroupData(
                    x: monthData.keys.toList().indexOf(e.key),
                    barRods: [BarChartRodData(toY: e.value.toDouble(), color: const Color(0xFF2ECC71), width: 20)],
                  )).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(monthData.keys.elementAt(value.toInt()), style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab() {
    final categoryStats = <int, int>{};
    
    for (var med in widget.medicines) {
      if (med.categoryId != null) {
        categoryStats[med.categoryId!] = (categoryStats[med.categoryId!] ?? 0) + 1;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...widget.categories.map((cat) => _buildCategoryRow(cat, categoryStats[cat.id] ?? 0)),
          if (widget.medicines.where((m) => m.categoryId == null).isNotEmpty)
            _buildCategoryRow(Category(name: 'Без категории', icon: '📦', color: 0xFF95A5A6), 
              widget.medicines.where((m) => m.categoryId == null).length),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(Category cat, int count) {
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
        trailing: Text('$count шт.', style: TextStyle(fontSize: 18, color: Color(cat.color), fontWeight: FontWeight.bold)),
      ),
    );
  }
}