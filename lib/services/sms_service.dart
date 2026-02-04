import 'dart:async';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/expense_model.dart';
import '../data/database_helper.dart';

class SMSService {
  static final SMSService _instance = SMSService._internal();
  factory SMSService() => _instance;
  SMSService._internal();

  final Telephony _telephony = Telephony.instance;
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  // Stream controller for new expense detection
  final StreamController<Expense> _expenseStreamController = 
      StreamController<Expense>.broadcast();
  Stream<Expense> get expenseStream => _expenseStreamController.stream;

  // Bank SMS sender identifiers
  final List<String> _bankSenders = [
    'SBI', 'SBIBNK', 'SBIINB', 'SBICRD',
    'HDFC', 'HDFCBK', 'HDFCBNK', 'HDFCCRD',
    'ICICI', 'ICICIB', 'ICICICC', 'ICICIBNK',
    'AXIS', 'AXISBK', 'AXISCRD', 'AXISBANK',
    'KOTAK', 'KOTAKB', 'KOTAKBK',
    'PNB', 'PNBBNK', 'PUNBNK',
    'BOB', 'BOIBNK', 'BANKBARODA',
    'CANBNK', 'CBI', 'INDUSBK',
    'YESBNK', 'YESBANK', 'IDFCFB',
    'FEDBNK', 'UNIONB', 'UCOBNK',
    'ALHBNK', 'ALHABANK',
    'PAYTM', 'PAYTMB', 'PHONEPE', 'GPAY', 'BHIM',
    'AMAZON', 'AMZNPAY', 'FLIPKART', 'FKPAY',
    'OLA', 'UBER', 'SWIGGY', 'ZOMATO',
  ];

  // Enhanced regex patterns for different transaction types
  final Map<String, RegExp> _patterns = {
    // Amount patterns
    'amount_inr': RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    'amount_only': RegExp(r'\b(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:Rs\.?|INR|₹)?', caseSensitive: false),
    
    // Merchant/UPI ID patterns
    'merchant': RegExp(r'(?:to|at|for|from|via)\s+([A-Za-z0-9\s@._&-]{2,50})', caseSensitive: false),
    'upi_id': RegExp(r'([a-zA-Z0-9._-]+@[a-zA-Z0-9]+)', caseSensitive: false),
    
    // Transaction ID patterns
    'txn_id': RegExp(r'(?:txn|transaction|ref|reference|utr|rrn)\s*(?:id|no|number)?[\s:#]*(\w{6,20})', caseSensitive: false),
    
    // Card/Account patterns
    'card_last4': RegExp(r'(?:card|a/c|account|x|xx|ending|ending with)\s*(?:no\.?)?\s*[Xx]*(\d{4})', caseSensitive: false),
    
    // Debit/Credit indicators
    'debit': RegExp(r'(?:debited|debit|deducted|paid|spent|withdrawn|charged)', caseSensitive: false),
    'credit': RegExp(r'(?:credited|credit|received|deposited|refund)', caseSensitive: false),
    
    // Date patterns
    'date': RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
    'date_word': RegExp(r'(\d{1,2})(?:st|nd|rd|th)?\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[,\s]+(\d{2,4})', caseSensitive: false),
  };

  // Category mapping based on merchant keywords
  final Map<String, List<String>> _categoryKeywords = {
    'food': ['swiggy', 'zomato', 'dominos', 'pizza', 'burger', 'restaurant', 'cafe', 'food', 'dining', 'eat', 'biryani', 'dosa', 'idli'],
    'transport': ['ola', 'uber', 'rapido', 'auto', 'cab', 'taxi', 'metro', 'bus', 'train', 'irctc', 'redbus', 'fuel', 'petrol', 'diesel'],
    'shopping': ['amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'snapdeal', 'shop', 'store', 'mart', 'mall', 'retail'],
    'groceries': ['bigbasket', 'grofers', 'blinkit', 'zepto', 'grocery', 'supermarket', 'kirana', 'vegetable', 'fruit'],
    'entertainment': ['netflix', 'prime', 'hotstar', 'sony', 'zee5', 'movie', 'cinema', 'theatre', 'bookmyshow', 'game', 'pubg', 'spotify'],
    'bills': ['electricity', 'water', 'gas', 'broadband', 'wifi', 'mobile', 'recharge', 'bill', 'utility', 'dth', 'tatasky', 'airtel'],
    'health': ['pharmacy', 'medical', 'hospital', 'clinic', 'doctor', 'medicine', 'apollo', 'medplus', '1mg', 'pharmeasy'],
    'education': ['course', 'class', 'tuition', 'book', 'udemy', 'coursera', 'byju', 'unacademy', 'vedantu', 'school', 'college'],
    'travel': ['booking', 'makemytrip', 'goibibo', 'cleartrip', 'yatra', 'hotel', 'flight', 'airline', 'irctc'],
  };

  /// Check and request SMS permissions
  Future<bool> requestPermissions() async {
    // Request SMS permission
    var smsStatus = await Permission.sms.request();
    
    // Request phone permission for better identification
    var phoneStatus = await Permission.phone.request();
    
    // For Android 13+, request notification permission
    var notificationStatus = await Permission.notification.request();
    
    return smsStatus.isGranted && phoneStatus.isGranted;
  }

  /// Check if permissions are granted
  Future<bool> hasPermissions() async {
    return await Permission.sms.isGranted && 
           await Permission.phone.isGranted;
  }

  /// Start listening for incoming SMS
  Future<void> startListening() async {
    if (!await hasPermissions()) {
      final granted = await requestPermissions();
      if (!granted) return;
    }

    _telephony.listenIncomingSms(
      onNewMessage: _onNewMessage,
      onBackgroundMessage: _onBackgroundMessage,
    );
  }

  /// Stop listening for SMS
  void stopListening() {
    // Telephony doesn't have explicit stop, but we can handle internally
  }

  /// Process new SMS message
  void _onNewMessage(SmsMessage message) {
    _processMessage(message);
  }

  /// Background message handler
  static void _onBackgroundMessage(SmsMessage message) {
    // Process in background
    final service = SMSService();
    service._processMessage(message);
  }

  /// Main message processing logic
  Future<void> _processMessage(SmsMessage message) async {
    final body = message.body ?? '';
    final sender = message.address ?? '';
    
    // Check if sender is from a bank
    if (!_isBankSender(sender) && !_containsBankKeywords(body)) {
      return;
    }

    // Check if it's a transaction message
    final transaction = _parseTransaction(body);
    if (transaction == null) return;

    // Check for duplicate
    if (transaction.transactionId != null) {
      final existing = await _db.getExpenseByTransactionId(transaction.transactionId!);
      if (existing != null) return; // Already exists
    }

    // Save to database
    final expense = Expense(
      title: transaction.merchant ?? 'Transaction',
      amount: transaction.amount,
      category: transaction.category,
      date: transaction.date ?? DateTime.now(),
      notes: 'Auto-captured from SMS',
      source: 'sms',
      merchantName: transaction.merchant,
      transactionId: transaction.transactionId,
      upiId: transaction.upiId,
      createdAt: DateTime.now(),
    );

    final id = await _db.insertExpense(expense);
    final savedExpense = expense.copyWith(id: id);
    
    // Notify listeners
    _expenseStreamController.add(savedExpense);
    
    // Update budget if applicable
    await _updateBudget(savedExpense);
  }

  /// Check if sender is a bank
  bool _isBankSender(String sender) {
    final upperSender = sender.toUpperCase();
    return _bankSenders.any((bank) => upperSender.contains(bank));
  }

  /// Check if message contains bank keywords
  bool _containsBankKeywords(String body) {
    final upperBody = body.toUpperCase();
    final keywords = [
      'BANK', 'DEBIT', 'CREDIT', 'UPI', 'TRANSACTION', 
      'ACCOUNT', 'BALANCE', 'PAYMENT', 'TRANSFER'
    ];
    return keywords.any((kw) => upperBody.contains(kw));
  }

  /// Parse transaction from SMS body
  TransactionInfo? _parseTransaction(String body) {
    try {
      // Check if it's a debit or credit
      final isDebit = _patterns['debit']!.hasMatch(body);
      final isCredit = _patterns['credit']!.hasMatch(body);
      
      // Only track expenses (debits) for now
      if (!isDebit && !isCredit) return null;

      // Extract amount
      final amount = _extractAmount(body);
      if (amount == null || amount <= 0) return null;

      // Extract merchant
      final merchant = _extractMerchant(body);

      // Extract UPI ID
      final upiId = _extractUPIId(body);

      // Extract transaction ID
      final txnId = _extractTransactionId(body);

      // Extract date
      final date = _extractDate(body);

      // Determine category
      final category = _determineCategory(body, merchant);

      return TransactionInfo(
        amount: amount,
        merchant: merchant,
        category: category,
        transactionId: txnId,
        upiId: upiId,
        date: date,
        isDebit: isDebit,
      );
    } catch (e) {
      print('Error parsing transaction: $e');
      return null;
    }
  }

  /// Extract amount from SMS
  double? _extractAmount(String body) {
    // Try INR/Rs pattern first
    var match = _patterns['amount_inr']!.firstMatch(body);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      return double.tryParse(amountStr ?? '');
    }

    // Try general amount pattern
    match = _patterns['amount_only']!.firstMatch(body);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      return double.tryParse(amountStr ?? '');
    }

    return null;
  }

  /// Extract merchant name from SMS
  String? _extractMerchant(String body) {
    // Try merchant pattern
    var match = _patterns['merchant']!.firstMatch(body);
    if (match != null) {
      return match.group(1)?.trim();
    }

    // Try UPI ID as merchant
    match = _patterns['upi_id']!.firstMatch(body);
    if (match != null) {
      return match.group(1)?.trim();
    }

    return null;
  }

  /// Extract UPI ID from SMS
  String? _extractUPIId(String body) {
    final match = _patterns['upi_id']!.firstMatch(body);
    return match?.group(1)?.trim();
  }

  /// Extract transaction ID from SMS
  String? _extractTransactionId(String body) {
    final match = _patterns['txn_id']!.firstMatch(body);
    return match?.group(1)?.trim();
  }

  /// Extract date from SMS
  DateTime? _extractDate(String body) {
    // Try standard date format
    var match = _patterns['date']!.firstMatch(body);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      var year = int.tryParse(match.group(3) ?? '');
      
      if (day != null && month != null) {
        if (year != null && year < 100) {
          year += 2000;
        }
        return DateTime(year ?? DateTime.now().year, month, day);
      }
    }

    // Try word date format
    match = _patterns['date_word']!.firstMatch(body);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final monthStr = match.group(2)?.toLowerCase();
      var year = int.tryParse(match.group(3) ?? '');
      
      final months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      };
      
      final month = months[monthStr];
      if (day != null && month != null) {
        if (year != null && year < 100) {
          year += 2000;
        }
        return DateTime(year ?? DateTime.now().year, month, day);
      }
    }

    return null;
  }

  /// Determine category based on merchant and body content
  String _determineCategory(String body, String? merchant) {
    final lowerBody = body.toLowerCase();
    final lowerMerchant = merchant?.toLowerCase() ?? '';

    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerBody.contains(keyword) || lowerMerchant.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'others';
  }

  /// Update budget when new expense is added
  Future<void> _updateBudget(Expense expense) async {
    final now = DateTime.now();
    await _db.updateBudgetSpent(expense.category, now, expense.amount);
  }

  /// Fetch all SMS from inbox (for initial sync)
  Future<Map<String, dynamic>> syncHistoricalSMS({int daysBack = 30}) async {
    if (!await hasPermissions()) {
      final granted = await requestPermissions();
      if (!granted) return {'added': [], 'duplicates': 0};
    }

    final expenses = <Expense>[];
    var duplicates = 0;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
    
    try {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      );

      for (final message in messages) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(message.date?.toString() ?? '0') ?? 0,
        );
        
        if (date.isBefore(cutoffDate)) continue;
        
        final body = message.body ?? '';
        final sender = message.address ?? '';
        
        if (!_isBankSender(sender) && !_containsBankKeywords(body)) continue;
        
        final transaction = _parseTransaction(body);
        if (transaction == null) continue;

        // Check for duplicate by ID first
        if (transaction.transactionId != null) {
          final existing = await _db.getExpenseByTransactionId(transaction.transactionId!);
          if (existing != null) {
            duplicates++;
            continue;
          }
        }

        // Check for duplicate by content (Amount, Time, Merchant)
        final potentialDuplicate = await _db.getPotentialDuplicate(
          transaction.amount, 
          transaction.merchant, 
          transaction.date ?? date
        );

        if (potentialDuplicate != null) {
          duplicates++;
          continue;
        }

        final expense = Expense(
          title: transaction.merchant ?? 'Transaction',
          amount: transaction.amount,
          category: transaction.category,
          date: transaction.date ?? date,
          notes: 'Auto-captured from SMS',
          source: 'sms',
          merchantName: transaction.merchant,
          transactionId: transaction.transactionId,
          upiId: transaction.upiId,
          createdAt: DateTime.now(),
        );

        final id = await _db.insertExpense(expense);
        expenses.add(expense.copyWith(id: id));
      }
    } catch (e) {
      print('Error syncing historical SMS: $e');
    }

    return {
      'added': expenses,
      'duplicates': duplicates,
    };
  }

  void dispose() {
    _expenseStreamController.close();
  }
}

/// Transaction information extracted from SMS
class TransactionInfo {
  final double amount;
  final String? merchant;
  final String category;
  final String? transactionId;
  final String? upiId;
  final DateTime? date;
  final bool isDebit;

  TransactionInfo({
    required this.amount,
    this.merchant,
    required this.category,
    this.transactionId,
    this.upiId,
    this.date,
    required this.isDebit,
  });
}
