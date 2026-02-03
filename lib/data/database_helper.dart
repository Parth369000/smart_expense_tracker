import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        source TEXT DEFAULT 'manual',
        merchantName TEXT,
        transactionId TEXT,
        upiId TEXT,
        isSynced INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        type TEXT DEFAULT 'debit'
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        budgetLimit REAL DEFAULT 0,
        isDefault INTEGER DEFAULT 0
      )
    ''');

    // SMS Patterns Table
    await db.execute('''
      CREATE TABLE sms_patterns (
        id TEXT PRIMARY KEY,
        bankName TEXT NOT NULL,
        pattern TEXT NOT NULL,
        amountRegex TEXT NOT NULL,
        merchantRegex TEXT,
        category TEXT,
        isDebit INTEGER DEFAULT 1,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Budgets Table
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId TEXT NOT NULL,
        amountLimit REAL NOT NULL,
        spent REAL DEFAULT 0,
        month TEXT NOT NULL,
        alertEnabled INTEGER DEFAULT 1,
        alertThreshold REAL DEFAULT 80
      )
    ''');

    // Recurring Expenses Table
    await db.execute('''
      CREATE TABLE recurring_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        frequency TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        nextDueDate TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        notes TEXT
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
    // Insert default SMS patterns
    await _insertDefaultSMSPatterns(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE expenses ADD COLUMN type TEXT DEFAULT 'debit'");
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final categories = [
      {'id': 'food', 'name': 'Food & Dining', 'icon': 'restaurant', 'color': 0xFFE53935, 'isDefault': 1},
      {'id': 'transport', 'name': 'Transportation', 'icon': 'directions_car', 'color': 0xFF1E88E5, 'isDefault': 1},
      {'id': 'shopping', 'name': 'Shopping', 'icon': 'shopping_bag', 'color': 0xFF8E24AA, 'isDefault': 1},
      {'id': 'entertainment', 'name': 'Entertainment', 'icon': 'movie', 'color': 0xFFFDD835, 'isDefault': 1},
      {'id': 'bills', 'name': 'Bills & Utilities', 'icon': 'receipt', 'color': 0xFF43A047, 'isDefault': 1},
      {'id': 'health', 'name': 'Health & Medical', 'icon': 'local_hospital', 'color': 0xFFFB8C00, 'isDefault': 1},
      {'id': 'education', 'name': 'Education', 'icon': 'school', 'color': 0xFF3949AB, 'isDefault': 1},
      {'id': 'travel', 'name': 'Travel', 'icon': 'flight', 'color': 0xFF00ACC1, 'isDefault': 1},
      {'id': 'groceries', 'name': 'Groceries', 'icon': 'local_grocery_store', 'color': 0xFF7CB342, 'isDefault': 1},
      {'id': 'others', 'name': 'Others', 'icon': 'more_horiz', 'color': 0xFF757575, 'isDefault': 1},
    ];

    for (var category in categories) {
      await db.insert('categories', category);
    }
  }

  Future<void> _insertDefaultSMSPatterns(Database db) async {
    final patterns = [
      // SBI Patterns
      {
        'id': 'sbi_debit_1',
        'bankName': 'SBI',
        'pattern': 'debited|debit',
        'amountRegex': r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)',
        'merchantRegex': r'(?:to|at|for)\s+([A-Za-z0-9\s&]+)',
        'category': 'others',
        'isDebit': 1,
      },
      // HDFC Patterns
      {
        'id': 'hdfc_debit_1',
        'bankName': 'HDFC',
        'pattern': 'debited|spent|paid',
        'amountRegex': r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)',
        'merchantRegex': r'(?:to|at|for)\s+([A-Za-z0-9\s&]+)',
        'category': 'others',
        'isDebit': 1,
      },
      // ICICI Patterns
      {
        'id': 'icici_debit_1',
        'bankName': 'ICICI',
        'pattern': 'debited',
        'amountRegex': r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)',
        'merchantRegex': r'(?:to|at)\s+([A-Za-z0-9\s&]+)',
        'category': 'others',
        'isDebit': 1,
      },
      // Axis Patterns
      {
        'id': 'axis_debit_1',
        'bankName': 'Axis',
        'pattern': 'debited|spent',
        'amountRegex': r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)',
        'merchantRegex': r'(?:to|at)\s+([A-Za-z0-9\s&]+)',
        'category': 'others',
        'isDebit': 1,
      },
      // UPI Patterns
      {
        'id': 'upi_generic',
        'bankName': 'UPI',
        'pattern': 'UPI|upi',
        'amountRegex': r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)',
        'merchantRegex': r'(?:to|at)\s+([A-Za-z0-9\s@]+)',
        'category': 'others',
        'isDebit': 1,
      },
    ];

    for (var pattern in patterns) {
      await db.insert('sms_patterns', pattern);
    }
  }

  // ==================== EXPENSE CRUD ====================

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses({int? limit, int? offset}) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => Expense.fromMap(e)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((e) => Expense.fromMap(e)).toList();
  }

  Future<List<Expense>> getExpensesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return maps.map((e) => Expense.fromMap(e)).toList();
  }

  Future<List<Expense>> getExpensesBySource(String source) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'source = ?',
      whereArgs: [source],
      orderBy: 'date DESC',
    );
    return maps.map((e) => Expense.fromMap(e)).toList();
  }

  Future<Expense?> getExpenseByTransactionId(String transactionId) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalExpenses({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      whereClause = 'WHERE date >= ? AND date <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }
    
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses $whereClause',
      whereArgs,
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // ==================== CATEGORY CRUD ====================

  Future<int> insertCategory(ExpenseCategory category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<ExpenseCategory>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name');
    return maps.map((e) => ExpenseCategory.fromMap(e)).toList();
  }

  Future<ExpenseCategory?> getCategoryById(String id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ExpenseCategory.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(ExpenseCategory category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ? AND isDefault = 0',
      whereArgs: [id],
    );
  }

  // ==================== SMS PATTERNS CRUD ====================

  Future<int> insertSMSPattern(SMSPattern pattern) async {
    final db = await database;
    return await db.insert('sms_patterns', pattern.toMap());
  }

  Future<List<SMSPattern>> getAllActivePatterns() async {
    final db = await database;
    final maps = await db.query(
      'sms_patterns',
      where: 'isActive = ?',
      whereArgs: [1],
    );
    return maps.map((e) => SMSPattern.fromMap(e)).toList();
  }

  Future<List<SMSPattern>> getPatternsByBank(String bankName) async {
    final db = await database;
    final maps = await db.query(
      'sms_patterns',
      where: 'bankName = ? AND isActive = ?',
      whereArgs: [bankName, 1],
    );
    return maps.map((e) => SMSPattern.fromMap(e)).toList();
  }

  // ==================== BUDGET CRUD ====================

  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<List<Budget>> getAllBudgetsForMonth(DateTime month) async {
    final db = await database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final maps = await db.query(
      'budgets',
      where: 'month = ?',
      whereArgs: [startOfMonth.toIso8601String()],
    );
    return maps.map((e) => Budget.fromMap(e)).toList();
  }

  Future<Budget?> getBudgetForCategory(String categoryId, DateTime month) async {
    final db = await database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final maps = await db.query(
      'budgets',
      where: 'categoryId = ? AND month = ?',
      whereArgs: [categoryId, startOfMonth.toIso8601String()],
    );
    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> updateBudgetSpent(String categoryId, DateTime month, double amount) async {
    final db = await database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    
    final budget = await getBudgetForCategory(categoryId, month);
    if (budget != null) {
      await db.update(
        'budgets',
        {'spent': budget.spent + amount},
        where: 'id = ?',
        whereArgs: [budget.id],
      );
    }
  }

  // ==================== ANALYTICS ====================

  Future<Map<String, double>> getCategoryTotals(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total 
      FROM expenses 
      WHERE date >= ? AND date <= ?
      GROUP BY category
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    return Map.fromEntries(
      result.map((e) => MapEntry(e['category'] as String, e['total'] as double)),
    );
  }

  Future<Map<String, double>> getDailyTotals(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT date(date) as day, SUM(amount) as total 
      FROM expenses 
      WHERE date >= ? AND date <= ?
      GROUP BY day
      ORDER BY day
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    return Map.fromEntries(
      result.map((e) => MapEntry(e['day'] as String, e['total'] as double)),
    );
  }

  Future<List<Expense>> getTopExpenses(int limit, DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'amount DESC',
      limit: limit,
    );
    return maps.map((e) => Expense.fromMap(e)).toList();
  }

  // ==================== UTILITY ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('budgets');
    // Keep categories and patterns
  }
}
