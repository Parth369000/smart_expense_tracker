import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/expense_model.dart';

class ReceiptScannerService {
  static final ReceiptScannerService _instance = ReceiptScannerService._internal();
  factory ReceiptScannerService() => _instance;
  ReceiptScannerService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  // Patterns for receipt parsing
  final Map<String, RegExp> _patterns = {
    'amount_total': RegExp(
      r'(?:total|grand total|amount|sum|balance)[\s:]*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    'amount_subtotal': RegExp(
      r'(?:subtotal|sub-total)[\s:]*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    'merchant_name': RegExp(
      r'^([A-Z][A-Za-z0-9\s&.,]+(?:Store|Shop|Mart|Restaurant|Cafe|Hotel|Hospital|Pharmacy|Ltd|Limited|Pvt)?)',
      caseSensitive: false,
    ),
    'date': RegExp(
      r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})',
    ),
    'time': RegExp(
      r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM|am|pm)?',
    ),
    'invoice_number': RegExp(
      r'(?:bill|invoice|receipt|txn|transaction)\s*(?:no\.?|number|#)?[\s:]*(\w[\w-]*)',
      caseSensitive: false,
    ),
    'tax_number': RegExp(
      r'(?:gst|vat|tax)\s*(?:no\.?|number|in)?[\s:]*(\w[\w-]*)',
      caseSensitive: false,
    ),
  };

  // Category keywords for receipt classification
  final Map<String, List<String>> _categoryKeywords = {
    'food': ['restaurant', 'cafe', 'food', 'dining', 'kitchen', 'biryani', 'pizza', 'burger'],
    'groceries': ['supermarket', 'grocery', 'mart', 'kirana', 'vegetable', 'fruit'],
    'shopping': ['fashion', 'clothing', 'apparel', 'store', 'mall', 'retail'],
    'health': ['pharmacy', 'medical', 'hospital', 'clinic', 'medicine', 'health'],
    'transport': ['fuel', 'petrol', 'diesel', 'transport', 'travel'],
    'bills': ['electricity', 'water', 'utility', 'bill', 'recharge'],
    'entertainment': ['movie', 'theatre', 'game', 'entertainment'],
  };

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Capture image from camera
  Future<File?> captureImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  /// Scan receipt and extract information
  Future<ScannedReceipt?> scanReceipt(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return null;
      }

      final lines = recognizedText.text.split('\n');
      final fullText = recognizedText.text;

      // Extract information
      final amount = _extractAmount(fullText, lines);
      final merchantName = _extractMerchantName(lines);
      final date = _extractDate(fullText);
      final category = _determineCategory(fullText, merchantName);
      final invoiceNumber = _extractInvoiceNumber(fullText);

      return ScannedReceipt(
        amount: amount,
        merchantName: merchantName,
        date: date,
        category: category,
        invoiceNumber: invoiceNumber,
        rawText: recognizedText.text,
        items: _extractItems(lines),
      );
    } catch (e) {
      print('Error scanning receipt: $e');
      return null;
    }
  }

  /// Extract amount from receipt
  double? _extractAmount(String fullText, List<String> lines) {
    // Try to find total amount first
    var match = _patterns['amount_total']!.firstMatch(fullText);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      return double.tryParse(amountStr ?? '');
    }

    // Try subtotal if total not found
    match = _patterns['amount_subtotal']!.firstMatch(fullText);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      return double.tryParse(amountStr ?? '');
    }

    // Look for any amount with Rs/INR/₹
    final amountPattern = RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)');
    final matches = amountPattern.allMatches(fullText);
    
    if (matches.isNotEmpty) {
      // Get the largest amount (likely the total)
      double? maxAmount;
      for (final m in matches) {
        final amountStr = m.group(1)?.replaceAll(',', '');
        final amount = double.tryParse(amountStr ?? '');
        if (amount != null && (maxAmount == null || amount > maxAmount)) {
          maxAmount = amount;
        }
      }
      return maxAmount;
    }

    return null;
  }

  /// Extract merchant name from receipt
  String? _extractMerchantName(List<String> lines) {
    // Try first few lines for merchant name
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Skip common headers
      if (_isHeaderLine(line)) continue;
      
      // Check if it looks like a merchant name
      if (line.length > 2 && line.length < 50) {
        // Clean up the name
        return line.replaceAll(RegExp(r'[^\w\s&.,-]'), '').trim();
      }
    }

    return null;
  }

  /// Check if line is a header (not merchant name)
  bool _isHeaderLine(String line) {
    final headers = [
      'tax invoice', 'retail invoice', 'cash memo', 'bill of supply',
      'gst invoice', 'original', 'duplicate', 'customer copy',
      'date', 'time', 'invoice', 'receipt', 'bill no',
    ];
    return headers.any((h) => line.toLowerCase().contains(h));
  }

  /// Extract date from receipt
  DateTime? _extractDate(String fullText) {
    final match = _patterns['date']!.firstMatch(fullText);
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
    return null;
  }

  /// Extract invoice number
  String? _extractInvoiceNumber(String fullText) {
    final match = _patterns['invoice_number']!.firstMatch(fullText);
    return match?.group(1)?.trim();
  }

  /// Determine category from receipt
  String _determineCategory(String fullText, String? merchantName) {
    final lowerText = fullText.toLowerCase();
    final lowerMerchant = merchantName?.toLowerCase() ?? '';

    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword) || lowerMerchant.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'others';
  }

  /// Extract items from receipt (basic implementation)
  List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];
    
    // Look for lines that look like items (contain quantity and price)
    final itemPattern = RegExp(
      r'^(.+?)\s+(\d+(?:\.\d+)?)\s+(?:x|@)?\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = itemPattern.firstMatch(line);
      if (match != null) {
        items.add(ReceiptItem(
          name: match.group(1)?.trim() ?? 'Unknown',
          quantity: double.tryParse(match.group(2) ?? '1') ?? 1,
          price: double.tryParse(match.group(3)?.replaceAll(',', '') ?? '0') ?? 0,
        ));
      }
    }

    return items;
  }

  /// Convert scanned receipt to Expense
  Expense toExpense(ScannedReceipt receipt) {
    return Expense(
      title: receipt.merchantName ?? 'Receipt Expense',
      amount: receipt.amount ?? 0,
      category: receipt.category,
      date: receipt.date ?? DateTime.now(),
      notes: 'Scanned from receipt\nInvoice: ${receipt.invoiceNumber ?? 'N/A'}',
      source: 'receipt',
      merchantName: receipt.merchantName,
      transactionId: receipt.invoiceNumber,
      createdAt: DateTime.now(),
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Scanned receipt data
class ScannedReceipt {
  final double? amount;
  final String? merchantName;
  final DateTime? date;
  final String category;
  final String? invoiceNumber;
  final String rawText;
  final List<ReceiptItem> items;

  ScannedReceipt({
    this.amount,
    this.merchantName,
    this.date,
    required this.category,
    this.invoiceNumber,
    required this.rawText,
    required this.items,
  });

  bool get isValid => amount != null && amount! > 0;
}

/// Receipt item
class ReceiptItem {
  final String name;
  final double quantity;
  final double price;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}
