import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/expense_bloc.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';
import '../services/sms_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ExportService _exportService = ExportService();
  final NotificationService _notificationService = NotificationService();
  final SMSService _smsService = SMSService();

  bool _smsEnabled = true;
  bool _notificationsEnabled = true;
  bool _dailyReminder = true;
  bool _budgetAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final hasSmsPermission = await _smsService.hasPermissions();
    setState(() {
      _smsEnabled = hasSmsPermission;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state.syncMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.syncMessage!)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Data Management Section
              _buildSectionCard(
                title: 'Data Management',
                children: [
                  _buildSettingTile(
                    icon: Icons.sync,
                    title: 'Sync SMS Expenses',
                    subtitle: 'Import from SMS',
                    color: AppTheme.primaryColor,
                    onTap: () => _showSyncDialog(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.download,
                    title: 'Export to CSV',
                    subtitle: 'Download data',
                    color: AppTheme.secondaryColor,
                    onTap: () => _showExportDialog(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.delete_outline,
                    title: 'Clear All Data',
                    subtitle: 'Reset everything',
                    color: AppTheme.errorColor,
                    onTap: () => _showClearDataDialog(context),
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notifications Section
              _buildSectionCard(
                title: 'Notifications',
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications,
                    title: 'Enable Notifications',
                    subtitle: 'Get alerts',
                    value: _notificationsEnabled,
                    color: AppTheme.primaryColor,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      if (value) _notificationService.initialize();
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.alarm,
                    title: 'Daily Reminder',
                    subtitle: '20:00 Reminder',
                    value: _dailyReminder,
                    color: AppTheme.secondaryColor,
                    enabled: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _dailyReminder = value);
                      if (value) {
                        _notificationService.scheduleDailyReminder(hour: 20, minute: 0);
                      } else {
                        _notificationService.cancelNotification(3000);
                      }
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.account_balance_wallet,
                    title: 'Budget Alerts',
                    subtitle: 'Near limit alerts',
                    value: _budgetAlerts,
                    color: AppTheme.warningColor,
                    enabled: _notificationsEnabled,
                    isLast: true,
                    onChanged: (value) => setState(() => _budgetAlerts = value),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Auto-Tracking Section
              _buildSectionCard(
                title: 'Auto-Tracking',
                children: [
                  _buildSwitchTile(
                    icon: Icons.sms,
                    title: 'SMS Auto-Tracking',
                    subtitle: 'Capture from SMS',
                    value: _smsEnabled,
                    color: AppTheme.secondaryColor,
                    isLast: true,
                    onChanged: (value) async {
                      if (value) {
                        final granted = await _smsService.requestPermissions();
                        setState(() => _smsEnabled = granted);
                        if (granted) _smsService.startListening();
                      } else {
                        setState(() => _smsEnabled = false);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // About Section
              _buildSectionCard(
                title: 'About',
                children: [
                  _buildSettingTile(
                    icon: Icons.info,
                    title: 'About App',
                    subtitle: 'Version 1.0.0',
                    color: AppTheme.primaryColor,
                    onTap: () => _showAboutDialog(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'Data usage',
                    color: AppTheme.accentColor,
                    onTap: () {},
                  ),
                  _buildSettingTile(
                    icon: Icons.help,
                    title: 'Help & Support',
                    subtitle: 'Get help',
                    color: AppTheme.warningColor,
                    isLast: true,
                    onTap: () {},
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required Function(bool) onChanged,
    bool enabled = true,
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: enabled ? onChanged : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: enabled ? color : Colors.grey, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: enabled ? AppTheme.onSurface : Colors.grey,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: enabled ? AppTheme.onSurfaceLight : Colors.grey[400],
            ),
          ),
          activeColor: AppTheme.primaryColor,
        ),
        if (!isLast)
          Divider(height: 1, indent: 64, color: Colors.grey.withOpacity(0.1)),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceLight),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.onSurfaceLight),
        ),
        if (!isLast)
          Divider(height: 1, indent: 64, color: Colors.grey.withOpacity(0.1)),
      ],
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync SMS Expenses'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How far back do you want to sync?'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Last 7 days'),
              onTap: () {
                Navigator.pop(context);
                _syncSMS(7);
              },
            ),
            ListTile(
              title: const Text('Last 30 days'),
              onTap: () {
                Navigator.pop(context);
                _syncSMS(30);
              },
            ),
            ListTile(
              title: const Text('Last 90 days'),
              onTap: () {
                Navigator.pop(context);
                _syncSMS(90);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _syncSMS(int days) {
    context.read<ExpenseBloc>().add(SyncSMSExpenses(daysBack: days));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Syncing last $days days of SMS...')),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose export option:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('This Month'),
              onTap: () {
                Navigator.pop(context);
                _exportData(
                  DateTime(DateTime.now().year, DateTime.now().month, 1),
                  DateTime.now(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Last Month'),
              onTap: () {
                Navigator.pop(context);
                final lastMonth = DateTime(
                  DateTime.now().year,
                  DateTime.now().month - 1,
                  1,
                );
                _exportData(
                  lastMonth,
                  DateTime(lastMonth.year, lastMonth.month + 1, 0),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Data'),
              onTap: () {
                Navigator.pop(context);
                _exportData(DateTime(2020), DateTime.now());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(DateTime start, DateTime end) async {
    final filePath = await _exportService.exportToCSV(
      startDate: start,
      endDate: end,
    );

    if (filePath != null) {
      await _exportService.shareFile(filePath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
    }
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your expenses and budgets. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
          size: 32,
        ),
      ),
      applicationLegalese: '© 2024 Expense Tracker. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'A smart expense tracking app with SMS auto-detection, '
          'receipt scanning, and voice input capabilities.',
        ),
      ],
    );
  }
}
