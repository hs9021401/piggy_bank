import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/transaction/transaction_event.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../main.dart';

class AddTransactionScreen extends StatefulWidget {
  final DataRefreshNotifier refreshNotifier;
  
  const AddTransactionScreen({super.key, required this.refreshNotifier});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _invoiceController = TextEditingController();
  
  TransactionType _type = TransactionType.expense;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final db = DatabaseService.instance;
    final categories = await db.getCategories(_type);
    
    setState(() {
      _categories = categories;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) async {
    setState(() {
      _type = type;
      _selectedCategoryId = null;
    });
    
    final db = DatabaseService.instance;
    final categories = await db.getCategories(type);
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請選擇分類')),
        );
        return;
      }

      final now = DateTime.now();
      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: double.parse(_amountController.text),
        note: _noteController.text,
        date: _selectedDate,
        categoryId: _selectedCategoryId!,
        walletId: 'default',
        type: _type,
        invoiceNumber: _invoiceController.text.isEmpty ? null : _invoiceController.text,
      );

      context.read<TransactionBloc>().add(AddTransaction(transaction));
      
      widget.refreshNotifier.refresh();
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('新增交易'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildAmountField(),
              const SizedBox(height: 24),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildNoteField(),
              const SizedBox(height: 24),
              _buildInvoiceField(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onTypeChanged(TransactionType.expense),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _type == TransactionType.expense
                      ? const Color(0xFFFF6B6B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '支出',
                    style: TextStyle(
                      color: _type == TransactionType.expense
                          ? Colors.white
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onTypeChanged(TransactionType.income),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _type == TransactionType.income
                      ? const Color(0xFF6BCB77)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '收入',
                    style: TextStyle(
                      color: _type == TransactionType.income
                          ? Colors.white
                          : Colors.grey,
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

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('金額', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: 'NT\$ ',
              border: InputBorder.none,
              hintText: '0.00',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '請輸入金額';
              }
              if (double.tryParse(value) == null) {
                return '請輸入有效數字';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('分類', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories.map((category) {
              final isSelected = category.id == _selectedCategoryId;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(category.color)
                        : Color(category.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Color(category.color) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconData(category.icon),
                        size: 18,
                        color: isSelected ? Colors.white : Color(category.color),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Color(category.color),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('yyyy年MM月dd日 EEEE');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('日期', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF6BCB77)),
                const SizedBox(width: 12),
                Text(
                  dateFormat.format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('備註（選填）', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '新增備註...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('電子發票號碼（選填）', style: TextStyle(color: Colors.grey)),
              TextButton.icon(
                onPressed: _scanInvoice,
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('掃描'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _invoiceController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '例：AB12345678',
            ),
          ),
        ],
      ),
    );
  }

  void _scanInvoice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('電子發票'),
        content: const Text(
          '請輸入發票號碼\n\n台灣電子發票格式：\n• 2碼英文+8碼數字（例：AB12345678）\n• 或26碼統一發票號碼',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6BCB77),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          '儲存交易',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      'work': Icons.work,
      'trending_up': Icons.trending_up,
      'card_giftcard': Icons.card_giftcard,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
