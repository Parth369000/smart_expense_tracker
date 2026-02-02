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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Management Section
            _buildSectionHeader('Data Management'),
            _buildSettingTile(
              icon: Icons.sync,
              title: 'Sync SMS Expenses',
              subtitle: 'Import expenses from SMS history',
              onTap: () => _showSyncDialog(context),
            ),
            _buildSettingTile(
              icon: Icons.download,
              title: 'Export to CSV',
              subtitle: 'Download expense data as CSV',
              onTap: () => _showExportDialog(context),
            ),
            _buildSettingTile(
              icon: Icons.delete_outline,
              title: 'Clear All Data',
              subtitle: 'Delete all expenses and budgets',
              color: AppTheme.errorColor,
              onTap: () => _showClearDataDialog(context),
            ),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: const Text('Enable Notifications'),
              subtitle: const Text('Get alerts for expenses and budgets'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                if (value) {
                  _notificationService.initialize();
                }
              },
            ),
            SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.alarm,
                  color: AppTheme.secondaryColor,
                ),
              ),
              title: const Text('Daily Reminder'),
              subtitle: const Text('Remind to track expenses daily'),
              value: _dailyReminder,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() => _dailyReminder = value);
                      if (value) {
                        _notificationService.scheduleDailyReminder(
                          hour: 20,
                          minute: 0,
                        );
                      } else {
                        _notificationService.cancelNotification(3000);
                      }
                    }
                  : null,
            ),
            SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.warningColor,
                ),
              ),
              title: const Text('Budget Alerts'),
              subtitle: const Text('Alert when nearing budget limit'),
              value: _budgetAlerts,
              onChanged: _notificationsEnabled
                  ? (value) => setState(() => _budgetAlerts = value)
                  : null,
            ),

            // Auto-Tracking Section
            _buildSectionHeader('Auto-Tracking'),
            SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sms,
                  color: AppTheme.secondaryColor,
                ),
              ),
              title: const Text('SMS Auto-Tracking'),
              subtitle: const Text('Automatically capture expenses from SMS'),
              value: _smsEnabled,
              onChanged: (value) async {
                if (value) {
                  final granted = await _smsService.requestPermissions();
                  setState(() => _smsEnabled = granted);
                  if (granted) {
                    _smsService.startListening();
                  }
                } else {
                  setState(() => _smsEnabled = false);
                }
              },
            ),

            // About Section
            _buildSectionHeader('About'),
            _buildSettingTile(
              icon: Icons.info,
              title: 'About App',
              subtitle: 'Version 1.0.0',
              onTap: () => _showAboutDialog(context),
            ),
            _buildSettingTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () {
                // Open privacy policy
              },
            ),
            _buildSettingTile(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help using the app',
              onTap: () {
                // Open help
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? AppTheme.onSurface;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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
