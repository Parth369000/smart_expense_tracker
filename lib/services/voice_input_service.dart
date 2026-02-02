import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/expense_model.dart';

class VoiceInputService {
  static final VoiceInputService _instance = VoiceInputService._internal();
  factory VoiceInputService() => _instance;
  VoiceInputService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  // Patterns for voice command parsing
  final Map<String, RegExp> _patterns = {
    // Amount patterns
    'amount': RegExp(
      r'(?:rupees?|rs\.?|inr|₹)?\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    'amount_words': RegExp(
      r'(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand)',
      caseSensitive: false,
    ),
    
    // Category indicators
    'category_food': RegExp(
      r'\b(food|lunch|dinner|breakfast|snack|meal|eat|restaurant|cafe|coffee|tea)\b',
      caseSensitive: false,
    ),
    'category_transport': RegExp(
      r'\b(transport|travel|cab|taxi|auto|bus|train|metro|fuel|petrol|diesel|ride)\b',
      caseSensitive: false,
    ),
    'category_shopping': RegExp(
      r'\b(shopping|shop|buy|purchase|clothes|dress|shoes|mall|store)\b',
      caseSensitive: false,
    ),
    'category_groceries': RegExp(
      r'\b(grocery|groceries|vegetable|fruit|milk|bread|rice|dal)\b',
      caseSensitive: false,
    ),
    'category_bills': RegExp(
      r'\b(bill|electricity|water|gas|phone|mobile|recharge|wifi|broadband)\b',
      caseSensitive: false,
    ),
    'category_entertainment': RegExp(
      r'\b(movie|film|show|entertainment|game|fun|party)\b',
      caseSensitive: false,
    ),
    'category_health': RegExp(
      r'\b(health|medical|doctor|medicine|pharmacy|hospital|clinic)\b',
      caseSensitive: false,
    ),
    'category_education': RegExp(
      r'\b(education|book|course|class|tuition|study|learning)\b',
      caseSensitive: false,
    ),
  };

  // Word to number mapping
  final Map<String, int> _wordToNumber = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
    'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19, 'twenty': 20,
    'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60, 'seventy': 70,
    'eighty': 80, 'ninety': 90, 'hundred': 100, 'thousand': 1000,
  };

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      print('Error initializing speech: $e');
      return false;
    }
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      return await initialize();
    }
    return _speechToText.isAvailable;
  }

  /// Start listening for voice input
  Future<void> startListening({
    required Function(String) onResult,
    required Function() onDone,
    String localeId = 'en_IN',
  }) async {
    if (!await isAvailable()) {
      onDone();
      return;
    }

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone();
        }
      },
      localeId: localeId,
      listenMode: ListenMode.confirmation,
      partialResults: false,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Check if currently listening
  bool get isListening => _speechToText.isListening;

  /// Parse voice input to expense
  VoiceParsedExpense? parseVoiceInput(String text) {
    try {
      // Extract amount
      final amount = _extractAmount(text);
      if (amount == null || amount <= 0) {
        return null;
      }

      // Extract category
      final category = _extractCategory(text);

      // Extract description/title
      final title = _extractTitle(text) ?? 'Voice Expense';

      // Extract merchant if mentioned
      final merchant = _extractMerchant(text);

      return VoiceParsedExpense(
        amount: amount,
        category: category,
        title: title,
        merchantName: merchant,
        rawText: text,
      );
    } catch (e) {
      print('Error parsing voice input: $e');
      return null;
    }
  }

  /// Extract amount from voice text
  double? _extractAmount(String text) {
    // Try numeric amount first
    final match = _patterns['amount']!.firstMatch(text);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      return double.tryParse(amountStr ?? '');
    }

    // Try word numbers
    return _parseWordNumbers(text);
  }

  /// Parse word numbers to actual number
  double? _parseWordNumbers(String text) {
    final matches = _patterns['amount_words']!.allMatches(text);
    if (matches.isEmpty) return null;

    double total = 0;
    double current = 0;

    for (final match in matches) {
      final word = match.group(0)?.toLowerCase() ?? '';
      final value = _wordToNumber[word] ?? 0;

      if (value == 100 || value == 1000) {
        current = (current == 0 ? 1.0 : current) * value;
        total += current;
        current = 0;
      } else if (value >= 20) {
        current += value;
      } else {
        current += value;
      }
    }

    total += current;
    return total > 0 ? total : null;
  }

  /// Extract category from voice text
  String _extractCategory(String text) {
    final lowerText = text.toLowerCase();

    if (_patterns['category_food']!.hasMatch(lowerText)) return 'food';
    if (_patterns['category_transport']!.hasMatch(lowerText)) return 'transport';
    if (_patterns['category_shopping']!.hasMatch(lowerText)) return 'shopping';
    if (_patterns['category_groceries']!.hasMatch(lowerText)) return 'groceries';
    if (_patterns['category_bills']!.hasMatch(lowerText)) return 'bills';
    if (_patterns['category_entertainment']!.hasMatch(lowerText)) return 'entertainment';
    if (_patterns['category_health']!.hasMatch(lowerText)) return 'health';
    if (_patterns['category_education']!.hasMatch(lowerText)) return 'education';

    return 'others';
  }

  /// Extract title/description from voice text
  String? _extractTitle(String text) {
    // Remove amount-related words
    var cleaned = text
        .replaceAll(_patterns['amount']!, '')
        .replaceAll(_patterns['amount_words']!, '');

    // Remove common filler words
    final fillers = [
      'spent', 'paid', 'for', 'on', 'at', 'to', 'the', 'a', 'an',
      'rupees', 'rs', 'inr', 'i', 'my', 'me', 'was', 'is', 'it',
      'today', 'yesterday', 'just', 'now', 'add', 'expense',
    ];
    
    for (final filler in fillers) {
      cleaned = cleaned.replaceAll(RegExp(r'\b' + filler + r'\b', caseSensitive: false), '');
    }

    // Clean up extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Capitalize first letter
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }

    return cleaned.isNotEmpty ? cleaned : null;
  }

  /// Extract merchant name from voice text
  String? _extractMerchant(String text) {
    // Look for "at" or "to" followed by a name
    final pattern = RegExp(r'(?:at|to|from)\s+([A-Za-z][A-Za-z0-9\s&]+)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  /// Convert parsed voice expense to Expense model
  Expense toExpense(VoiceParsedExpense parsed) {
    return Expense(
      title: parsed.title,
      amount: parsed.amount,
      category: parsed.category,
      date: DateTime.now(),
      notes: 'Added via voice: "${parsed.rawText}"',
      source: 'voice',
      merchantName: parsed.merchantName,
      createdAt: DateTime.now(),
    );
  }

  /// Get quick voice command suggestions
  List<String> getQuickCommands() {
    return [
      'Spent 500 rupees on lunch',
      'Paid 200 for auto ride',
      'Spent 1500 on groceries',
      'Paid electricity bill 1200',
      'Spent 3000 on shopping',
      'Paid 800 for dinner at restaurant',
    ];
  }

  void dispose() {
    _speechToText.cancel();
  }
}

/// Parsed expense from voice input
class VoiceParsedExpense {
  final double amount;
  final String category;
  final String title;
  final String? merchantName;
  final String rawText;

  VoiceParsedExpense({
    required this.amount,
    required this.category,
    required this.title,
    this.merchantName,
    required this.rawText,
  });

  bool get isValid => amount > 0 && title.isNotEmpty;
}
