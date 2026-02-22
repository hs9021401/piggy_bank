import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../main.dart';

class StatsScreen extends StatefulWidget {
  final DataRefreshNotifier refreshNotifier;
  
  const StatsScreen({super.key, required this.refreshNotifier});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime _selectedMonth = DateTime.now();
  Map<String, double> _categoryExpenses = {};
  double _totalExpense = 0;
  double _totalIncome = 0;
  List<Category> _categories = [];
  List<Map<String, dynamic>> _monthlyData = [];
  int _selectedChartType = 0;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier.addListener(_onRefresh);
    _loadData();
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    _loadData();
  }

  void _loadData() async {
    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    
    final db = DatabaseService.instance;
    final expenses = await db.getExpensesByCategory(startDate, endDate);
    final totalExpense = await db.getTotalExpense(startDate, endDate);
    final totalIncome = await db.getTotalIncome(startDate, endDate);
    final categories = await db.getCategories(TransactionType.expense);
    final monthlyData = await _getMonthlyTrendData();
    
    setState(() {
      _categoryExpenses = expenses;
      _totalExpense = totalExpense;
      _totalIncome = totalIncome;
      _categories = categories;
      _monthlyData = monthlyData;
    });
  }

  Future<List<Map<String, dynamic>>> _getMonthlyTrendData() async {
    final db = DatabaseService.instance;
    final List<Map<String, dynamic>> data = [];
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
      final startDate = month;
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      final income = await db.getTotalIncome(startDate, endDate);
      final expense = await db.getTotalExpense(startDate, endDate);
      
      data.add({
        'month': month,
        'income': income,
        'expense': expense,
      });
    }
    
    return data;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('統計'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMonthSelector(),
            _buildSummaryCards(),
            _buildChartTypeSelector(),
            _buildChart(),
            _buildCategoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthFormat = DateFormat('yyyy年 MMMM');
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            monthFormat.format(_selectedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final currencyFormat = NumberFormat.currency(symbol: 'NT\$ ');
    final diff = _totalIncome - _totalExpense;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              '收入',
              _totalIncome,
              const Color(0xFF6BCB77),
              currencyFormat,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              '支出',
              _totalExpense,
              const Color(0xFFFF6B6B),
              currencyFormat,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              '結餘',
              diff.abs(),
              diff >= 0 ? const Color(0xFF6BCB77) : const Color(0xFFFF6B6B),
              currencyFormat,
              prefix: diff >= 0 ? '+' : '-',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, NumberFormat format, {String prefix = ''}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '$prefix${format.format(amount)}',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedChartType = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedChartType == 0 ? const Color(0xFF6BCB77) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '收支趨勢',
                    style: TextStyle(
                      color: _selectedChartType == 0 ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedChartType = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedChartType == 1 ? const Color(0xFF6BCB77) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '支出分布',
                    style: TextStyle(
                      color: _selectedChartType == 1 ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_selectedChartType == 0) {
      return _buildTrendChart();
    } else {
      return _buildPieChart();
    }
  }

  Widget _buildTrendChart() {
    if (_monthlyData.isEmpty) {
      return Container(
        height: 250,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('尚無資料')),
      );
    }

    final spots = _monthlyData.asMap().entries.map((entry) {
      final expense = entry.value['expense'] as double;
      return FlSpot(entry.key.toDouble(), expense);
    }).toList();

    final incomeSpots = _monthlyData.asMap().entries.map((entry) {
      final income = entry.value['income'] as double;
      return FlSpot(entry.key.toDouble(), income);
    }).toList();

    double maxY = 0;
    double minY = 0;
    for (final d in _monthlyData) {
      final e = d['expense'] as double;
      final i = d['income'] as double;
      if (e > maxY) maxY = e;
      if (i > maxY) maxY = i;
    }
    if (maxY == 0) {
      maxY = 100;
    } else {
      maxY = maxY * 1.3;
    }
    minY = 0;

    return Container(
      height: 280,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('收支趨勢（近6個月）', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _monthlyData.length) {
                          final month = _monthlyData[index]['month'] as DateTime;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${month.month}月',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFFF6B6B),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: const Color(0xFF6BCB77),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6BCB77).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('支出', const Color(0xFFFF6B6B)),
              const SizedBox(width: 24),
              _buildLegendItem('收入', const Color(0xFF6BCB77)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPieChart() {
    if (_categoryExpenses.isEmpty || _totalExpense == 0) {
      return Container(
        height: 250,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('尚無支出資料', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final sections = _categoryExpenses.entries.map((entry) {
      final category = _categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(id: entry.key, name: '其他', icon: 'more_horiz', color: 0xFFB8B8B8, type: TransactionType.expense),
      );
      final percentage = (entry.value / _totalExpense * 100).toStringAsFixed(1);
      
      return PieChartSectionData(
        color: Color(category.color),
        value: entry.value,
        title: '$percentage%',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final currencyFormat = NumberFormat.currency(symbol: 'NT\$ ');
    final sortedCategories = _categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('依分類', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...sortedCategories.map((entry) {
            final category = _categories.firstWhere(
              (c) => c.id == entry.key,
              orElse: () => Category(id: entry.key, name: '其他', icon: 'more_horiz', color: 0xFFB8B8B8, type: TransactionType.expense),
            );
            final percentage = _totalExpense > 0 ? (entry.value / _totalExpense * 100) : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(category.color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getIconData(category.icon), color: Color(category.color), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text(currencyFormat.format(entry.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(Color(category.color)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_bag': Icons.shopping_bag,
      'movie': Icons.movie,
      'receipt': Icons.receipt,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'more_horiz': Icons.more_horiz,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
