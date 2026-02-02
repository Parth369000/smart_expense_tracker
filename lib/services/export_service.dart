import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../data/database_helper.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Export expenses to CSV
  Future<String?> exportToCSV({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
  }) async {
    try {
      // Get expenses
      List<Expense> expenses;
      if (startDate != null && endDate != null) {
        expenses = await _db.getExpensesByDateRange(startDate, endDate);
      } else {
        expenses = await _db.getAllExpenses();
      }

      // Filter by categories if specified
      if (categories != null && categories.isNotEmpty) {
        expenses = expenses.where((e) => categories.contains(e.category)).toList();
      }

      if (expenses.isEmpty) {
        return null;
      }

      // Create CSV data
      final csvData = <List<dynamic>>[];
      
      // Header row
      csvData.add([
        'Date',
        'Title',
        'Amount',
        'Category',
        'Source',
        'Merchant',
        'Transaction ID',
        'UPI ID',
        'Notes',
      ]);

      // Data rows
      for (final expense in expenses) {
        csvData.add([
          DateFormat('yyyy-MM-dd HH:mm').format(expense.date),
          expense.title,
          expense.amount,
          expense.category,
          expense.source,
          expense.merchantName ?? '',
          expense.transactionId ?? '',
          expense.upiId ?? '',
          expense.notes ?? '',
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'expenses_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      print('Error exporting to CSV: $e');
      return null;
    }
  }

  /// Share exported file
  Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Expense Report',
        text: 'Here is my expense report.',
      );
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  /// Generate monthly summary report
  Future<String?> generateMonthlyReport(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      
      final expenses = await _db.getExpensesByDateRange(startDate, endDate);
      final categoryTotals = await _db.getCategoryTotals(startDate, endDate);
      
      if (expenses.isEmpty) {
        return null;
      }

      final csvData = <List<dynamic>>[];
      
      // Summary section
      csvData.add(['Monthly Expense Report']);
      csvData.add(['Period', DateFormat('MMMM yyyy').format(startDate)]);
      csvData.add(['Total Expenses', expenses.fold<double>(0, (sum, e) => sum + e.amount)]);
      csvData.add([]);
      
      // Category breakdown
      csvData.add(['Category Breakdown']);
      csvData.add(['Category', 'Amount', 'Percentage']);
      
      final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      for (final entry in categoryTotals.entries) {
        final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(2) : '0';
        csvData.add([entry.key, entry.value, '$percentage%']);
      }
      csvData.add([]);
      
      // Detailed expenses
      csvData.add(['Detailed Expenses']);
      csvData.add([
        'Date', 'Title', 'Amount', 'Category', 'Source', 'Merchant', 'Notes'
      ]);
      
      for (final expense in expenses) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(expense.date),
          expense.title,
          expense.amount,
          expense.category,
          expense.source,
          expense.merchantName ?? '',
          expense.notes ?? '',
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'monthly_report_${DateFormat('yyyyMM').format(startDate)}.csv';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      print('Error generating monthly report: $e');
      return null;
    }
  }

  /// Generate yearly summary report
  Future<String?> generateYearlyReport(int year) async {
    try {
      final csvData = <List<dynamic>>[];
      
      csvData.add(['Yearly Expense Report']);
      csvData.add(['Year', year.toString()]);
      csvData.add([]);
      
      // Monthly breakdown
      csvData.add(['Monthly Breakdown']);
      csvData.add(['Month', 'Total Expenses']);
      
      double yearlyTotal = 0;
      for (int month = 1; month <= 12; month++) {
        final startDate = DateTime(year, month, 1);
        final endDate = DateTime(year, month + 1, 0);
        final expenses = await _db.getExpensesByDateRange(startDate, endDate);
        final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
        yearlyTotal += total;
        csvData.add([DateFormat('MMMM').format(startDate), total]);
      }
      
      csvData.add(['Yearly Total', yearlyTotal]);
      csvData.add([]);
      
      // Category breakdown for the year
      csvData.add(['Category Breakdown']);
      csvData.add(['Category', 'Amount', 'Percentage']);
      
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31);
      final categoryTotals = await _db.getCategoryTotals(startDate, endDate);
      
      for (final entry in categoryTotals.entries) {
        final percentage = yearlyTotal > 0 
            ? (entry.value / yearlyTotal * 100).toStringAsFixed(2) 
            : '0';
        csvData.add([entry.key, entry.value, '$percentage%']);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'yearly_report_$year.csv';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      print('Error generating yearly report: $e');
      return null;
    }
  }

  /// Get all exported files
  Future<List<File>> getExportedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.csv'))
          .toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      print('Error getting exported files: $e');
      return [];
    }
  }

  /// Delete exported file
  Future<bool> deleteExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}
