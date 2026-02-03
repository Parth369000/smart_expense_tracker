import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/expense_bloc.dart';
import '../models/expense_model.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_card.dart';
import '../widgets/summary_card.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const AnalyticsScreen(),
    const BudgetScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddOptions(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            )
          : null,
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Expense',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _buildAddOption(
              context,
              icon: Icons.edit,
              color: AppTheme.primaryColor,
              label: 'Manual Entry',
              subtitle: 'Add expense details manually',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddExpenseScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAddOption(
              context,
              icon: Icons.camera_alt,
              color: AppTheme.secondaryColor,
              label: 'Scan Receipt',
              subtitle: 'Extract from receipt photo',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddExpenseScreen(source: 'receipt'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAddOption(
              context,
              icon: Icons.mic,
              color: AppTheme.accentColor,
              label: 'Voice Input',
              subtitle: 'Speak to add expense',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddExpenseScreen(source: 'voice'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(const LoadExpenses(limit: 50));
    context.read<ExpenseBloc>().add(const LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${DateFormat('a').format(DateTime.now()) == 'AM' ? 'Morning' : 'Evening'}!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track Your Expenses',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // TODO: Open notifications
                    },
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
            ),
          ),

          // Summary Cards
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: BlocBuilder<ExpenseBloc, ExpenseState>(
                builder: (context, state) {
                  double totalIncome = 0;
                  double totalExpense = 0;
                  double todayExpense = 0;
                  
                  // Use data from unified state
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final monthStart = DateTime(now.year, now.month, 1);

                  for (final expense in state.expenses) {
                    if (expense.type == 'credit') {
                      totalIncome += expense.amount;
                    } else {
                      totalExpense += expense.amount;
                      
                      // Fix: Compare dates properly by stripping time
                      final expenseDate = DateTime(
                        expense.date.year, 
                        expense.date.month, 
                        expense.date.day
                      );
                      
                      if (expenseDate.isAtSameMomentAs(today)) {
                        todayExpense += expense.amount;
                      }
                    }
                  }

                  final balance = totalIncome - totalExpense;

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      SummaryCard(
                        title: 'Today\'s Spend',
                        amount: '₹${todayExpense.toStringAsFixed(0)}',
                        subtitle: DateFormat('dd MMM').format(DateTime.now()),
                        icon: Icons.today,
                        color: AppTheme.warningColor,
                      ),
                      SummaryCard(
                        title: 'Balance',
                        amount: '₹${balance.toStringAsFixed(0)}',
                        subtitle: 'Available',
                        icon: Icons.account_balance,
                        color: AppTheme.primaryColor,
                      ),
                      SummaryCard(
                        title: 'Credited',
                        amount: '₹${totalIncome.toStringAsFixed(0)}',
                        subtitle: 'Total Income',
                        icon: Icons.arrow_downward,
                        color: AppTheme.secondaryColor,
                      ),
                      SummaryCard(
                        title: 'Debited',
                        amount: '₹${totalExpense.toStringAsFixed(0)}',
                        subtitle: 'Total Expense',
                        icon: Icons.arrow_upward,
                        color: AppTheme.accentColor,
                      ),
                      SummaryCard(
                        title: 'Today\'s Spend',
                        amount: '₹${todayExpense.toStringAsFixed(0)}',
                        subtitle: DateFormat('dd MMM').format(DateTime.now()),
                        icon: Icons.today,
                        color: AppTheme.warningColor,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        QuickActionButton(
                          label: 'Sync SMS',
                          icon: Icons.sms,
                          color: AppTheme.primaryColor,
                          onTap: () {
                            context.read<ExpenseBloc>().add(
                              const SyncSMSExpenses(daysBack: 30),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Syncing SMS expenses...'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        QuickActionButton(
                          label: 'View Reports',
                          icon: Icons.pie_chart,
                          color: AppTheme.secondaryColor,
                          onTap: () {
                            // Navigate to analytics
                          },
                        ),
                        const SizedBox(width: 12),
                        QuickActionButton(
                          label: 'Set Budget',
                          icon: Icons.savings,
                          color: AppTheme.accentColor,
                          onTap: () {
                            // Navigate to budget
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent Expenses Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Expenses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // View all
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
          ),

          // Recent Expenses List
          BlocBuilder<ExpenseBloc, ExpenseState>(
            builder: (context, state) {
              if (state.status == ExpenseStatus.loading && state.expenses.isEmpty) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const ExpenseShimmerCard(),
                    childCount: 5,
                  ),
                );
              }

              if (state.expenses.isNotEmpty) {
                 return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final expense = state.expenses[index];
                      // Find category synchronously from state
                      final category = state.categories.firstWhere(
                        (c) => c.id == expense.category,
                        orElse: () => ExpenseCategory(
                          id: expense.category,
                          name: expense.category,
                          icon: 'more_horiz',
                          color: AppTheme.categoryColors['others']!.value,
                        ),
                      );

                      return ExpenseCard(
                        expense: expense,
                        category: category,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddExpenseScreen(
                                expense: expense,
                              ),
                            ),
                          );
                        },
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Expense'),
                              content: const Text(
                                'Are you sure you want to delete this expense?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<ExpenseBloc>().add(
                                      DeleteExpense(expense.id!),
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: AppTheme.errorColor),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    childCount: state.expenses.length > 20 
                        ? 20 
                        : state.expenses.length,
                  ),
                );
              }

              if (state.expenses.isEmpty && state.status == ExpenseStatus.success) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.onSurfaceLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first expense or sync SMS',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
              }

              if (state.status == ExpenseStatus.failure) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'Error: ${state.errorMessage ?? "Unknown error"}',
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
