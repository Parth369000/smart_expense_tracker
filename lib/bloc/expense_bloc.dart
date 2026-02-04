import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';
import '../data/database_helper.dart';
import '../services/sms_service.dart';
import '../services/notification_service.dart';

// Events
abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {
  final int? limit;
  final int? offset;
  
  const LoadExpenses({this.limit, this.offset});

  @override
  List<Object?> get props => [limit, offset];
}

class LoadExpensesByDateRange extends ExpenseEvent {
  final DateTime startDate;
  final DateTime endDate;
  
  const LoadExpensesByDateRange({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class AddExpense extends ExpenseEvent {
  final Expense expense;
  
  const AddExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

class UpdateExpense extends ExpenseEvent {
  final Expense expense;
  
  const UpdateExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

class DeleteExpense extends ExpenseEvent {
  final int id;
  
  const DeleteExpense(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadCategories extends ExpenseEvent {
  const LoadCategories();
}

class AddCategory extends ExpenseEvent {
  final ExpenseCategory category;
  
  const AddCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class LoadBudgets extends ExpenseEvent {
  final DateTime month;
  
  const LoadBudgets({required this.month});

  @override
  List<Object?> get props => [month];
}

class SetBudget extends ExpenseEvent {
  final Budget budget;
  
  const SetBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}

class LoadAnalytics extends ExpenseEvent {
  final DateTime startDate;
  final DateTime endDate;
  
  const LoadAnalytics({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class SyncSMSExpenses extends ExpenseEvent {
  final int? daysBack;
  
  const SyncSMSExpenses({this.daysBack});

  @override
  List<Object?> get props => [daysBack];
}

class LoadDashboardSummary extends ExpenseEvent {
  const LoadDashboardSummary();
}

class OnSMSExpenseDetected extends ExpenseEvent {
  final Expense expense;
  
  const OnSMSExpenseDetected(this.expense);

  @override
  List<Object?> get props => [expense];
}

// State
enum ExpenseStatus { initial, loading, success, failure }

class ExpenseState extends Equatable {
  final ExpenseStatus status;
  final List<Expense> expenses;
  final List<ExpenseCategory> categories;
  final List<Budget> budgets;
  final ExpenseSummary? summary;
  final bool hasReachedMax;
  final String? errorMessage;
  final int? smsSyncCount;
  final String? syncMessage;
  final DashboardMetrics? dashboardMetrics;

  const ExpenseState({
    this.status = ExpenseStatus.initial,
    this.expenses = const [],
    this.categories = const [],
    this.budgets = const [],
    this.summary,
    this.hasReachedMax = false,
    this.errorMessage,
    this.smsSyncCount,
    this.dashboardMetrics,
    this.syncMessage,
  });

  ExpenseState copyWith({
    ExpenseStatus? status,
    List<Expense>? expenses,
    List<ExpenseCategory>? categories,
    List<Budget>? budgets,
    ExpenseSummary? summary,
    bool? hasReachedMax,
    String? errorMessage,
    int? smsSyncCount,
    String? syncMessage,
    DashboardMetrics? dashboardMetrics,
  }) {
    return ExpenseState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      budgets: budgets ?? this.budgets,
      summary: summary ?? this.summary,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage, // Reset error on new state unless explicitly passed
      smsSyncCount: smsSyncCount, // Reset sync count unless explicitly passed
      syncMessage: syncMessage,
      dashboardMetrics: dashboardMetrics ?? this.dashboardMetrics,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    expenses, 
    categories, 
    budgets, 
    summary, 
    hasReachedMax, 
    errorMessage, 
    smsSyncCount,
    syncMessage,
    dashboardMetrics
  ];
}

// BLoC
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SMSService _smsService = SMSService();
  final NotificationService _notificationService = NotificationService();
  
  StreamSubscription<Expense>? _smsSubscription;

  ExpenseBloc() : super(const ExpenseState()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<LoadExpensesByDateRange>(_onLoadExpensesByDateRange);
    on<AddExpense>(_onAddExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<LoadBudgets>(_onLoadBudgets);
    on<SetBudget>(_onSetBudget);
    on<LoadAnalytics>(_onLoadAnalytics);
    on<SyncSMSExpenses>(_onSyncSMSExpenses);
    on<OnSMSExpenseDetected>(_onSMSExpenseDetected);
    on<LoadDashboardSummary>(_onLoadDashboardSummary);

    // Listen to SMS expense stream
    _smsSubscription = _smsService.expenseStream.listen((expense) {
      add(OnSMSExpenseDetected(expense));
    });

    // Start SMS listening
    _smsService.startListening();
  }

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseStatus.loading));
    try {
      final expenses = await _db.getAllExpenses(
        limit: event.limit,
        offset: event.offset,
      );
      emit(state.copyWith(
        status: ExpenseStatus.success,
        expenses: expenses,
        hasReachedMax: event.limit != null && expenses.length < event.limit!,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure, 
        errorMessage: 'Failed to load expenses: $e'
      ));
    }
  }

  Future<void> _onLoadExpensesByDateRange(
    LoadExpensesByDateRange event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseStatus.loading));
    try {
      final expenses = await _db.getExpensesByDateRange(
        event.startDate,
        event.endDate,
      );
      emit(state.copyWith(
        status: ExpenseStatus.success,
        expenses: expenses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to load expenses: $e'
      ));
    }
  }

  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      final id = await _db.insertExpense(event.expense);
      final expense = event.expense.copyWith(id: id);
      
      // Update budget
      await _db.updateBudgetSpent(
        expense.category,
        DateTime.now(),
        expense.amount,
      );
      
      // Show notification
      final category = await _db.getCategoryById(expense.category);
      await _notificationService.showExpenseAdded(
        expense,
        category?.name ?? expense.category,
      );
      
      // Instead of reloading everything, we can just append if it's recent
      // But for simplicity/correctness with sorting, let's reload or insert
      final updatedExpenses = List<Expense>.from(state.expenses)..insert(0, expense);
      emit(state.copyWith(
        status: ExpenseStatus.success,
        expenses: updatedExpenses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to add expense: $e'
      ));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _db.updateExpense(event.expense);
      final updatedExpenses = state.expenses.map((e) {
        return e.id == event.expense.id ? event.expense : e;
      }).toList();
      
      emit(state.copyWith(
        status: ExpenseStatus.success,
        expenses: updatedExpenses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to update expense: $e'
      ));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _db.deleteExpense(event.id);
      final updatedExpenses = state.expenses.where((e) => e.id != event.id).toList();
      emit(state.copyWith(
        status: ExpenseStatus.success,
        expenses: updatedExpenses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to delete expense: $e'
      ));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<ExpenseState> emit,
  ) async {
    // Only set loading if we don't have categories yet to avoid flicker
    if (state.categories.isEmpty) {
      emit(state.copyWith(status: ExpenseStatus.loading));
    }
    try {
      final categories = await _db.getAllCategories();
      emit(state.copyWith(
        status: ExpenseStatus.success,
        categories: categories,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to load categories: $e'
      ));
    }
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _db.insertCategory(event.category);
      final updatedCategories = List<ExpenseCategory>.from(state.categories)..add(event.category);
      emit(state.copyWith(
        status: ExpenseStatus.success,
        categories: updatedCategories,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to add category: $e'
      ));
    }
  }

  Future<void> _onLoadBudgets(
    LoadBudgets event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseStatus.loading));
    try {
      final budgets = await _db.getAllBudgetsForMonth(event.month);
      emit(state.copyWith(
        status: ExpenseStatus.success,
        budgets: budgets,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to load budgets: $e'
      ));
    }
  }

  Future<void> _onSetBudget(
    SetBudget event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      final existing = await _db.getBudgetForCategory(
        event.budget.categoryId,
        event.budget.month,
      );
      
      if (existing != null) {
        await _db.updateBudget(event.budget.copyWith(id: existing.id));
      } else {
        await _db.insertBudget(event.budget);
      }
      
      // Reload budgets to get strict sync
      add(LoadBudgets(month: event.budget.month));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to set budget: $e'
      ));
    }
  }

  Future<void> _onLoadAnalytics(
    LoadAnalytics event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseStatus.loading));
    try {
      final expenses = await _db.getExpensesByDateRange(
        event.startDate,
        event.endDate,
      );
      
      final categoryTotals = await _db.getCategoryTotals(
        event.startDate,
        event.endDate,
      );
      
      final dailyTotals = await _db.getDailyTotals(
        event.startDate,
        event.endDate,
      );
      
      final topExpenses = await _db.getTopExpenses(
        10,
        event.startDate,
        event.endDate,
      );

      final totalExpenses = expenses.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );

      final days = event.endDate.difference(event.startDate).inDays + 1;
      final averageDaily = days > 0 ? totalExpenses / days : 0.0;

      final summary = ExpenseSummary(
        totalExpenses: totalExpenses,
        totalIncome: 0, 
        categoryTotals: categoryTotals,
        dailyTotals: dailyTotals,
        weeklyTotals: {},
        monthlyTotals: {}, 
        topExpenses: topExpenses,
        averageDaily: averageDaily,
        averageMonthly: averageDaily * 30,
      );

      emit(state.copyWith(
        status: ExpenseStatus.success,
        summary: summary,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to load analytics: $e'
      ));
    }
  }

  Future<void> _onSyncSMSExpenses(
    SyncSMSExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseStatus.loading));
    try {
      final result = await _smsService.syncHistoricalSMS(
        daysBack: event.daysBack ?? 30,
      );
      
      final added = result['added'] as List<Expense>;
      final duplicates = result['duplicates'] as int;

      // Reload expenses after sync
      add(const LoadExpenses(limit: 50));
      
      String message;
      if (added.isEmpty) {
        message = duplicates > 0 
            ? 'Data is up to date ($duplicates duplicates found)'
            : 'No new expenses found';
      } else {
        message = 'Synced ${added.length} expenses' + 
            (duplicates > 0 ? ' ($duplicates duplicates skipped)' : '');
      }
      
      emit(state.copyWith(
        smsSyncCount: added.length,
        syncMessage: message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to sync SMS expenses: $e'
      ));
    }
  }

  Future<void> _onSMSExpenseDetected(
    OnSMSExpenseDetected event,
    Emitter<ExpenseState> emit,
  ) async {
    // Show notification for auto-captured expense
    final category = await _db.getCategoryById(event.expense.category);
    await _notificationService.showExpenseAdded(
      event.expense,
      category?.name ?? event.expense.category,
    );
    
    // Insert into current list if valid
    final updatedExpenses = List<Expense>.from(state.expenses)..insert(0, event.expense);
    emit(state.copyWith(expenses: updatedExpenses));
    // Also refresh dashboard metrics if we can
    add(const LoadDashboardSummary());
  }

  Future<void> _onLoadDashboardSummary(
    LoadDashboardSummary event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      final metrics = await _db.getDashboardMetrics();
      // Also load recent expenses (limit 5 for dashboard)
      final expenses = await _db.getAllExpenses(limit: 5);
      
      emit(state.copyWith(
        status: ExpenseStatus.success,
        dashboardMetrics: metrics,
        expenses: expenses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure, 
        errorMessage: 'Failed to load dashboard: $e'
      ));
    }
  }

  @override
  Future<void> close() {
    _smsSubscription?.cancel();
    _smsService.dispose();
    return super.close();
  }
}
