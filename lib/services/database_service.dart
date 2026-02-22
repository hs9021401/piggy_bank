import 'dart:convert';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._();

  DatabaseService._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = p.join(dbPath, 'piggy_bank.db');

    return await openDatabase(
      dbFilePath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        type INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        color INTEGER NOT NULL,
        type INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        note TEXT NOT NULL,
        date INTEGER NOT NULL,
        categoryId TEXT NOT NULL,
        walletId TEXT NOT NULL,
        type INTEGER NOT NULL,
        invoiceNumber TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories(id),
        FOREIGN KEY (walletId) REFERENCES wallets(id)
      )
    ''');

    await _insertDefaultCategories(db);
    await _insertDefaultWallet(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['food', '餐飲', 'restaurant', 0xFFFF6B6B, 1]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['transport', '交通', 'directions_car', 0xFF4ECDC4, 1]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['shopping', '購物', 'shopping_bag', 0xFFFFE66D, 1]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['entertainment', '娛樂', 'movie', 0xFF95E1D3, 1]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['bills', '帳單', 'receipt', 0xFFF38181, 1]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['health', '醫療', 'local_hospital', 0xFFAA96DA, 1]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['education', '教育', 'school', 0xFFFCBF49, 1]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['other_expense', '其他', 'more_horiz', 0xFFB8B8B8, 1]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['salary', '薪水', 'work', 0xFF6BCB77, 0]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['investment', '投資', 'trending_up', 0xFF4D96FF, 0]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['gift', '禮物', 'card_giftcard', 0xFFFF9F45, 0]);
    await db.execute('INSERT OR IGNORE INTO categories (id, name, icon, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['other_income', '其他', 'more_horiz', 0xFFB8B8B8, 0]);
  }

  Future<void> _insertDefaultWallet(Database db) async {
    await db.execute('INSERT OR IGNORE INTO wallets (id, name, balance, color, type) VALUES (?, ?, ?, ?, ?)', 
      ['cash', '現金', 0.0, 0xFF6BCB77, 0]);
  }

  Future<List<Category>> getCategories(TransactionType? type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (type != null) {
      maps = await db.query('categories', where: 'type = ?', whereArgs: [type.index]);
    } else {
      maps = await db.query('categories');
    }

    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Wallet>> getWallets() async {
    final db = await database;
    final maps = await db.query('wallets');
    return maps.map((map) => Wallet.fromMap(map)).toList();
  }

  Future<Wallet?> getWallet(String id) async {
    final db = await database;
    final maps = await db.query('wallets', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Wallet.fromMap(maps.first);
  }

  Future<void> insertWallet(Wallet wallet) async {
    final db = await database;
    await db.insert('wallets', wallet.toMap());
  }

  Future<void> updateWallet(Wallet wallet) async {
    final db = await database;
    await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> deleteWallet(String id) async {
    final db = await database;
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateWalletBalance(String walletId, double amount) async {
    final db = await database;
    final wallet = await getWallet(walletId);
    if (wallet != null) {
      await db.update(
        'wallets',
        {'balance': wallet.balance + amount},
        where: 'id = ?',
        whereArgs: [walletId],
      );
    }
  }

  Future<List<Transaction>> getTransactions({
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (walletId != null && startDate != null && endDate != null) {
      where = 'walletId = ? AND date >= ? AND date <= ?';
      whereArgs = [walletId, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch];
    } else if (walletId != null) {
      where = 'walletId = ?';
      whereArgs = [walletId];
    }

    final maps = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<void> insertTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
    final amount = transaction.type == TransactionType.income
        ? transaction.amount
        : -transaction.amount;
    await updateWalletBalance(transaction.walletId, amount);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    final transactions = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (transactions.isNotEmpty) {
      final transaction = Transaction.fromMap(transactions.first);
      final amount = transaction.type == TransactionType.income
          ? -transaction.amount
          : transaction.amount;
      await updateWalletBalance(transaction.walletId, amount);
    }
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalBalance() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(balance) as total FROM wallets');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalExpense(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      [TransactionType.expense.index, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalIncome(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      [TransactionType.income.index, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT categoryId, SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ? GROUP BY categoryId',
      [TransactionType.expense.index, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );

    final Map<String, double> categoryExpenses = {};
    for (final row in result) {
      categoryExpenses[row['categoryId'] as String] = (row['total'] as num).toDouble();
    }
    return categoryExpenses;
  }

  Future<void> processPeriodicTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final periodicJson = prefs.getString('periodic_transactions');
    if (periodicJson == null) return;

    final periodicTransactions = List<Map<String, dynamic>>.from(
      (json.decode(periodicJson) as List).map((e) => Map<String, dynamic>.from(e))
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final db = await database;

    for (final periodic in periodicTransactions) {
      final periodicId = periodic['id'] as String?;
      final startTimestamp = periodic['startDate'] as int?;
      final endTimestamp = periodic['endDate'] as int?;
      if (startTimestamp == null) continue;

      final startDate = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
      final startDayOnly = DateTime(startDate.year, startDate.month, startDate.day);
      final endDate = endTimestamp != null ? DateTime.fromMillisecondsSinceEpoch(endTimestamp) : null;

      if (today.isBefore(startDayOnly)) continue;
      if (endDate != null && today.isAfter(endDate)) continue;

      final frequency = periodic['frequency'] as int;
      
      final monthsSinceStart = (now.year - startDate.year) * 12 + (now.month - startDate.month);
      
      if (monthsSinceStart < 0) continue;
      
      if (monthsSinceStart % frequency != 0) continue;

      final amount = (periodic['amount'] as num).toDouble();
      final categoryId = periodic['categoryId'] as String;
      
      final transactionDate = DateTime(now.year, now.month, startDate.day);
      final transactionDayOnly = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);
      
      if (transactionDayOnly.isAfter(today)) continue;

      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final existingTransactions = await db.query(
        'transactions',
        where: 'categoryId = ? AND amount = ? AND note = ? AND date >= ? AND date <= ?',
        whereArgs: [
          categoryId,
          amount,
          periodic['note'] ?? '',
          monthStart.millisecondsSinceEpoch,
          monthEnd.millisecondsSinceEpoch,
        ],
      );

      if (existingTransactions.isEmpty) {
        final transaction = Transaction(
          id: const Uuid().v4(),
          amount: amount,
          note: periodic['note'] ?? '',
          date: transactionDayOnly,
          categoryId: categoryId,
          walletId: 'default',
          type: TransactionType.expense,
        );
        await insertTransaction(transaction);
      }
    }
  }
}
