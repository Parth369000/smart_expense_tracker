import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/expense_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _isInitialized = true;
  }

  /// Handle notification tap
  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen
    print('Notification tapped: ${response.payload}');
  }

  /// Show instant notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'expense_channel',
      'Expense Notifications',
      channelDescription: 'Notifications for expense tracking',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id: id, title: title, body: body, notificationDetails: details, payload: payload);
  }

  /// Show budget alert notification
  Future<void> showBudgetAlert(Budget budget, String categoryName) async {
    final percentage = budget.percentageUsed.toStringAsFixed(1);
    
    await showNotification(
      id: 1000 + (budget.id ?? 0),
      title: 'Budget Alert: $categoryName',
      body: 'You\'ve used $percentage% of your ₹${budget.amountLimit.toStringAsFixed(0)} budget. '
            'Remaining: ₹${(budget.amountLimit - budget.spent).toStringAsFixed(0)}',
      payload: 'budget_${budget.categoryId}',
    );
  }

  /// Show expense added notification
  Future<void> showExpenseAdded(Expense expense, String categoryName) async {
    await showNotification(
      id: 2000 + (expense.id ?? 0),
      title: 'Expense Added',
      body: '₹${expense.amount.toStringAsFixed(0)} for $categoryName - ${expense.title}',
      payload: 'expense_${expense.id}',
    );
  }

  /// Show daily reminder notification
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminder',
      channelDescription: 'Daily expense tracking reminder',
      importance: Importance.defaultImportance,
    );

    const iosDetails = DarwinNotificationDetails();

    await _notifications.zonedSchedule(
      id: 3000,
      title: 'Daily Expense Check',
      body: 'Don\'t forget to track your expenses today!',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Show weekly summary notification
  Future<void> scheduleWeeklySummary({
    required int dayOfWeek, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    var daysUntil = dayOfWeek - now.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    
    var scheduledDate = DateTime(
      now.year, now.month, now.day + daysUntil, hour, minute,
    );

    const androidDetails = AndroidNotificationDetails(
      'weekly_summary',
      'Weekly Summary',
      channelDescription: 'Weekly expense summary',
    );

    const iosDetails = DarwinNotificationDetails();

    await _notifications.zonedSchedule(
      id: 4000,
      title: 'Weekly Expense Summary',
      body: 'Check your spending for this week!',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Show monthly budget reminder
  Future<void> scheduleMonthlyBudgetReminder({
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, dayOfMonth, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = DateTime(now.year, now.month + 1, dayOfMonth, hour, minute);
    }

    const androidDetails = AndroidNotificationDetails(
      'monthly_budget',
      'Monthly Budget',
      channelDescription: 'Monthly budget planning reminder',
    );

    const iosDetails = DarwinNotificationDetails();

    await _notifications.zonedSchedule(
      id: 5000,
      title: 'Set Your Monthly Budget',
      body: 'It\'s time to plan your budget for this month!',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
