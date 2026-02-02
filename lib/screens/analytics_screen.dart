import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/expense_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/charts.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  void _loadAnalytics() {
    context.read<ExpenseBloc>().add(LoadAnalytics(
      startDate: _startDate,
      endDate: _endDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Range Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: 'From',
                    date: _startDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: _endDate,
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked);
                        _loadAnalytics();
                      }
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, size: 20),
                ),
                Expanded(
                  child: _buildDateButton(
                    label: 'To',
                    date: _endDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                        _loadAnalytics();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Quick Date Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickFilter('This Week', () {
                    setState(() {
                      _startDate = DateTime.now().subtract(
                        Duration(days: DateTime.now().weekday - 1),
                      );
                      _endDate = DateTime.now();
                    });
                    _loadAnalytics();
                  }),
                  const SizedBox(width: 8),
                  _buildQuickFilter('This Month', () {
                    setState(() {
                      _startDate = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        1,
                      );
                      _endDate = DateTime.now();
                    });
                    _loadAnalytics();
                  }),
                  const SizedBox(width: 8),
                  _buildQuickFilter('Last Month', () {
                    setState(() {
                      final lastMonth = DateTime(
                        DateTime.now().year,
                        DateTime.now().month - 1,
                        1,
                      );
                      _startDate = lastMonth;
                      _endDate = DateTime(
                        lastMonth.year,
                        lastMonth.month + 1,
                        0,
                      );
                    });
                    _loadAnalytics();
                  }),
                  const SizedBox(width: 8),
                  _buildQuickFilter('Last 3 Months', () {
                    setState(() {
                      _startDate = DateTime(
                        DateTime.now().year,
                        DateTime.now().month - 3,
                        1,
                      );
                      _endDate = DateTime.now();
                    });
                    _loadAnalytics();
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCategoriesTab(),
                _buildTrendsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilter(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
      labelStyle: TextStyle(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state.status == ExpenseStatus.loading && state.summary == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.summary != null) {
          final summary = state.summary!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary Stats
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    StatCard(
                      label: 'Total Expenses',
                      value: '₹${summary.totalExpenses.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet,
                      color: AppTheme.primaryColor,
                    ),
                    StatCard(
                      label: 'Daily Average',
                      value: '₹${summary.averageDaily.toStringAsFixed(0)}',
                      icon: Icons.today,
                      color: AppTheme.secondaryColor,
                    ),
                    StatCard(
                      label: 'Monthly Average',
                      value: '₹${summary.averageMonthly.toStringAsFixed(0)}',
                      icon: Icons.calendar_month,
                      color: AppTheme.accentColor,
                    ),
                    StatCard(
                      label: 'Transaction Count',
                      value: '${summary.topExpenses.length}',
                      icon: Icons.receipt_long,
                      color: AppTheme.warningColor,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Top Expenses
                if (summary.topExpenses.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Expenses',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...summary.topExpenses.take(5).map((expense) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.getCategoryColor(
                            expense.category,
                          ).withOpacity(0.2),
                          child: Icon(
                            Icons.receipt,
                            color: AppTheme.getCategoryColor(expense.category),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          expense.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy').format(expense.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Text(
                          '₹${expense.amount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          );
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
                  'Error loading analytics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'Unknown error',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCategoriesTab() {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state.status == ExpenseStatus.loading && state.summary == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.summary != null) {
          final categoryTotals = state.summary!.categoryTotals;

          if (categoryTotals.isEmpty) {
            return const Center(
              child: Text('No category data available'),
            );
          }

          final total = categoryTotals.values.reduce((a, b) => a + b);
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pie Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CategoryPieChart(data: categoryTotals),
                  ),
                ),

                const SizedBox(height: 16),

                // Category List
                Card(
                  child: Column(
                    children: sortedCategories.map((entry) {
                      final percentage = total > 0 
                          ? (entry.value / total * 100).toStringAsFixed(1) 
                          : '0';
                      final color = AppTheme.getCategoryColor(entry.key);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(
                            Icons.category,
                            color: color,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          entry.key[0].toUpperCase() + entry.key.substring(1),
                        ),
                        subtitle: LinearProgressIndicator(
                          value: total > 0 ? entry.value / total : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${entry.value.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTrendsTab() {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state.status == ExpenseStatus.loading && state.summary == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.summary != null) {
          final dailyTotals = state.summary!.dailyTotals;

          if (dailyTotals.isEmpty) {
            return const Center(
              child: Text('No trend data available'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Daily Bar Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Spending',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: DailyBarChart(data: dailyTotals),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Weekly Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending Insights',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInsightItem(
                          icon: Icons.trending_up,
                          color: AppTheme.primaryColor,
                          title: 'Highest Spending Day',
                          value: _getHighestSpendingDay(dailyTotals),
                        ),
                        const Divider(),
                        _buildInsightItem(
                          icon: Icons.trending_down,
                          color: AppTheme.secondaryColor,
                          title: 'Lowest Spending Day',
                          value: _getLowestSpendingDay(dailyTotals),
                        ),
                        const Divider(),
                        _buildInsightItem(
                          icon: Icons.calendar_today,
                          color: AppTheme.accentColor,
                          title: 'Average Daily Spend',
                          value: '₹${state.summary!.averageDaily.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getHighestSpendingDay(Map<String, double> dailyTotals) {
    if (dailyTotals.isEmpty) return 'N/A';
    final maxEntry = dailyTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${DateFormat('dd MMM').format(DateTime.parse(maxEntry.key))} (₹${maxEntry.value.toStringAsFixed(0)})';
  }

  String _getLowestSpendingDay(Map<String, double> dailyTotals) {
    if (dailyTotals.isEmpty) return 'N/A';
    final minEntry = dailyTotals.entries.reduce((a, b) => a.value < b.value ? a : b);
    return '${DateFormat('dd MMM').format(DateTime.parse(minEntry.key))} (₹${minEntry.value.toStringAsFixed(0)})';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
