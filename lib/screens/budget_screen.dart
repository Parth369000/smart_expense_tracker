import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/expense_bloc.dart';
import '../models/expense_model.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  void _loadBudgets() {
    context.read<ExpenseBloc>().add(LoadBudgets(month: _selectedMonth));
    context.read<ExpenseBloc>().add(LoadCategories());
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
    });
    _loadBudgets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            onPressed: () => _showSetBudgetDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          // Budget Content
          Expanded(
            child: BlocBuilder<ExpenseBloc, ExpenseState>(
              builder: (context, state) {
                if (state.status == ExpenseStatus.loading && state.budgets.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.budgets.isNotEmpty) {
                  return _buildBudgetList(state.budgets);
                }
                
                // If loaded but empty
                if (state.status == ExpenseStatus.success && state.budgets.isEmpty) {
                   return _buildBudgetList([]);
                }

                if (state.status == ExpenseStatus.failure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage ?? 'Error loading budgets',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(List<Budget> budgets) {
    if (budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No budgets set',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set budgets to track your spending',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showSetBudgetDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Set Budget'),
            ),
          ],
        ),
      );
    }

    // Calculate totals
    double totalBudget = 0;
    double totalSpent = 0;
    for (final budget in budgets) {
      totalBudget += budget.amountLimit;
      totalSpent += budget.spent;
    }
    final totalRemaining = (totalBudget - totalSpent).clamp(0.0, double.infinity);
    final overallProgress = totalBudget > 0 ? totalSpent / totalBudget : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Budget',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${totalBudget.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Remaining',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${totalRemaining.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: totalRemaining > 0 ? AppTheme.successColor : AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: overallProgress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        overallProgress >= 1.0
                            ? AppTheme.errorColor
                            : overallProgress >= 0.8
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                      ),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(overallProgress * 100).toStringAsFixed(1)}% used',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: overallProgress >= 0.8 ? AppTheme.errorColor : AppTheme.onSurfaceLight,
                          fontWeight: overallProgress >= 0.8 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      Text(
                        '₹${totalSpent.toStringAsFixed(0)} spent',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Category Budgets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Budgets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showSetBudgetDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Budget List
          ...budgets.map((budget) {
            return BlocBuilder<ExpenseBloc, ExpenseState>(
              builder: (context, state) {
                String categoryName = budget.categoryId;
                Color categoryColor = AppTheme.categoryColors['others']!;
                
                // Use unified state categories
                if (state.categories.isNotEmpty) {
                    final category = state.categories.firstWhere(
                    (c) => c.id == budget.categoryId,
                    orElse: () => ExpenseCategory(
                      id: budget.categoryId,
                      name: budget.categoryId,
                      icon: 'more_horiz',
                      color: AppTheme.categoryColors['others']!.value,
                    ),
                  );
                  categoryName = category.name;
                  categoryColor = Color(category.color);
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: BudgetProgressChart(
                      spent: budget.spent,
                      limit: budget.amountLimit,
                      categoryName: categoryName,
                      color: categoryColor,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext context) {
    final categories = context.read<ExpenseBloc>().state.categories;

    if (categories.isEmpty) {
      context.read<ExpenseBloc>().add(const LoadCategories());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading categories...')),
      );
      return;
    }

    String selectedCategory = categories.first.id;
    final amountController = TextEditingController();
    final thresholdController = TextEditingController(text: '80');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category.icon),
                            color: Color(category.color),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Amount Field
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                ),
                const SizedBox(height: 16),

                // Alert Threshold
                TextFormField(
                  controller: thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Alert Threshold (%)',
                    hintText: '80',
                    prefixIcon: Icon(Icons.notifications),
                    suffixText: '%',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                final threshold = double.tryParse(thresholdController.text) ?? 80;

                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid amount')),
                  );
                  return;
                }

                final budget = Budget(
                  categoryId: selectedCategory,
                  amountLimit: amount,
                  month: _selectedMonth,
                  alertThreshold: threshold,
                );

                context.read<ExpenseBloc>().add(SetBudget(budget));
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget set successfully!')),
                );
              },
              child: const Text('Set Budget'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_bag': Icons.shopping_bag,
      'movie': Icons.movie,
      'receipt': Icons.receipt,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'flight': Icons.flight,
      'local_grocery_store': Icons.local_grocery_store,
      'more_horiz': Icons.more_horiz,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
