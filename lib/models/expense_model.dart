import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final String source; // 'sms', 'manual', 'voice', 'receipt'
  final String? merchantName;
  final String? transactionId;
  final String? upiId;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.source = 'manual',
    this.merchantName,
    this.transactionId,
    this.upiId,
    this.isSynced = false,
    required this.createdAt,
    this.updatedAt,
  });

  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
    String? source,
    String? merchantName,
    String? transactionId,
    String? upiId,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      merchantName: merchantName ?? this.merchantName,
      transactionId: transactionId ?? this.transactionId,
      upiId: upiId ?? this.upiId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
      'source': source,
      'merchantName': merchantName,
      'transactionId': transactionId,
      'upiId': upiId,
      'isSynced': isSynced ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      source: map['source'] as String? ?? 'manual',
      merchantName: map['merchantName'] as String?,
      transactionId: map['transactionId'] as String?,
      upiId: map['upiId'] as String?,
      isSynced: map['isSynced'] == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id, title, amount, category, date, notes, 
        source, merchantName, transactionId, upiId, 
        isSynced, createdAt, updatedAt
      ];
}

// Category Model
class ExpenseCategory extends Equatable {
  final String id;
  final String name;
  final String icon;
  final int color;
  final double budgetLimit;
  final bool isDefault;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budgetLimit = 0,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'budgetLimit': budgetLimit,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as int,
      budgetLimit: map['budgetLimit'] as double? ?? 0,
      isDefault: map['isDefault'] == 1,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, budgetLimit, isDefault];
}

// SMS Pattern Model for parsing
class SMSPattern extends Equatable {
  final String id;
  final String bankName;
  final String pattern;
  final String amountRegex;
  final String? merchantRegex;
  final String? category;
  final bool isDebit;
  final bool isActive;

  const SMSPattern({
    required this.id,
    required this.bankName,
    required this.pattern,
    required this.amountRegex,
    this.merchantRegex,
    this.category,
    this.isDebit = true,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'pattern': pattern,
      'amountRegex': amountRegex,
      'merchantRegex': merchantRegex,
      'category': category,
      'isDebit': isDebit ? 1 : 0,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory SMSPattern.fromMap(Map<String, dynamic> map) {
    return SMSPattern(
      id: map['id'] as String,
      bankName: map['bankName'] as String,
      pattern: map['pattern'] as String,
      amountRegex: map['amountRegex'] as String,
      merchantRegex: map['merchantRegex'] as String?,
      category: map['category'] as String?,
      isDebit: map['isDebit'] == 1,
      isActive: map['isActive'] == 1,
    );
  }

  @override
  List<Object?> get props => [
        id, bankName, pattern, amountRegex, 
        merchantRegex, category, isDebit, isActive
      ];
}

// Budget Model
class Budget extends Equatable {
  final int? id;
  final String categoryId;
  final double amountLimit;
  final double spent;
  final DateTime month;
  final bool alertEnabled;
  final double alertThreshold; // Percentage (0-100)

  const Budget({
    this.id,
    required this.categoryId,
    required this.amountLimit,
    this.spent = 0,
    required this.month,
    this.alertEnabled = true,
    this.alertThreshold = 80,
  });

  double get percentageUsed => amountLimit > 0 ? (spent / amountLimit) * 100 : 0;
  bool get isOverBudget => spent > amountLimit;
  bool get shouldAlert => alertEnabled && percentageUsed >= alertThreshold;

  Budget copyWith({
    int? id,
    String? categoryId,
    double? amountLimit,
    double? spent,
    DateTime? month,
    bool? alertEnabled,
    double? alertThreshold,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amountLimit: amountLimit ?? this.amountLimit,
      spent: spent ?? this.spent,
      month: month ?? this.month,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amountLimit': amountLimit,
      'spent': spent,
      'month': month.toIso8601String(),
      'alertEnabled': alertEnabled ? 1 : 0,
      'alertThreshold': alertThreshold,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as String,
      amountLimit: map['amountLimit'] as double,
      spent: map['spent'] as double? ?? 0,
      month: DateTime.parse(map['month'] as String),
      alertEnabled: map['alertEnabled'] == 1,
      alertThreshold: map['alertThreshold'] as double? ?? 80,
    );
  }

  @override
  List<Object?> get props => [id, categoryId, amountLimit, spent, month, alertEnabled, alertThreshold];
}

// Analytics Summary Model
class ExpenseSummary extends Equatable {
  final double totalExpenses;
  final double totalIncome;
  final Map<String, double> categoryTotals;
  final Map<String, double> dailyTotals;
  final Map<String, double> weeklyTotals;
  final Map<String, double> monthlyTotals;
  final List<Expense> topExpenses;
  final double averageDaily;
  final double averageMonthly;

  const ExpenseSummary({
    required this.totalExpenses,
    required this.totalIncome,
    required this.categoryTotals,
    required this.dailyTotals,
    required this.weeklyTotals,
    required this.monthlyTotals,
    required this.topExpenses,
    required this.averageDaily,
    required this.averageMonthly,
  });

  double get netSavings => totalIncome - totalExpenses;
  double get savingsRate => totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0;

  @override
  List<Object?> get props => [
        totalExpenses, totalIncome, categoryTotals, 
        dailyTotals, weeklyTotals, monthlyTotals, 
        topExpenses, averageDaily, averageMonthly
      ];
}
