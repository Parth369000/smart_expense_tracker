import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/expense_model.dart';

class VoiceInputService {
  static final VoiceInputService _instance = VoiceInputService._internal();
  factory VoiceInputService() => _instance;
  VoiceInputService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  // Gujarati to English digit mapping
  final Map<String, String> _digitMap = {
    '૦': '0', '૧': '1', '૨': '2', '૩': '3', '૪': '4',
    '૫': '5', '૬': '6', '૭': '7', '૮': '8', '૯': '9'
  };

  // Patterns for voice command parsing
  final Map<String, RegExp> _patterns = {
    // Amount patterns (supports "5k", "1.5k", currency symbols)
    'amount': RegExp(
      r'(?:rupees?|rs\.?|inr|₹|રૂ|રૂપિયા)?\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?k?)',
      caseSensitive: false,
    ),
    
    // Date indicators
    'today': RegExp(r'\b(today|aaje|આજે)\b', caseSensitive: false),
    'yesterday': RegExp(r'\b(yesterday|gaikale|ગઈકાલે)\b', caseSensitive: false),
    
    // Category Keywords (English + Gujarati)
    'cat_food': RegExp(r'\b(food|lunch|dinner|breakfast|snack|restaurant|cafe|coffee|tea|zomato|swiggy|khoorak|jamvanu|nasto|khavanu|bhojan|જમવાનું|નાસ્તો|ખોરાક)\b', caseSensitive: false),
    'cat_transport': RegExp(r'\b(transport|travel|cab|taxi|auto|bus|train|metro|fuel|petrol|diesel|uber|ola|rapido|bhadu|rickshaw|rent|bada|ભાડું|રિક્ષા|બસ)\b', caseSensitive: false),
    'cat_shopping': RegExp(r'\b(shopping|shop|buy|clothes|dress|shoes|mall|store|myntra|amazon|flipkart|kapda|kharidi|કપડાં|ખરીદી)\b', caseSensitive: false),
    'cat_groceries': RegExp(r'\b(grocery|groceries|vegetable|fruit|milk|bread|rice|dal|bigbasket|blinkit|zepto|shakbhaji|dudh|kariyana|શાકભાજી|દૂધ|કરિયાણું)\b', caseSensitive: false),
    'cat_bills': RegExp(r'\b(bill|electricity|water|gas|phone|mobile|recharge|wifi|broadband|light|bijli|lightbill|વીજળી|બિલ)\b', caseSensitive: false),
    'cat_entertainment': RegExp(r'\b(movie|film|show|entertainment|game|party|netflix|prime|hotstar|theater|cinema|manoranjan|મનોરંજન)\b', caseSensitive: false),
    'cat_health': RegExp(r'\b(health|medical|doctor|medicine|pharmacy|hospital|clinic|dava|dawakhana|hospital|દવા|ડોક્ટર)\b', caseSensitive: false),
    'cat_education': RegExp(r'\b(education|book|course|class|tuition|study|school|college|fee|bhantar|schcool|abhayas|શિક્ષણ|ચોપડી|ફી)\b', caseSensitive: false),
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

  /// Start listening for voice input (English + Gujarati)
  Future<void> startListening({
    required Function(String) onResult,
    required Function() onDone,
  }) async {
    if (!await _isInitialized && !await initialize()) {
      onDone();
      return;
    }

    // Prefer Hindi/Gujarati/English mix if available, mostly auto-detected by engine on Android
    // Specifying accurate locale helps. 
    // Android often supports "en_IN" which handles Hinglish well.
    // For specific Gujarati users, "gu_IN" is better.
    // We try to listen with auto-detection or fallback to en_IN/gu_IN.
    
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone();
        }
      },
      localeId: 'gu_IN', // Prioritizing Gujarati/Indian English mix
      listenMode: ListenMode.search, // Better for short phrases
      partialResults: false,
    );
  }

  Future<void> stopListening() async => await _speechToText.stop();

  bool get isListening => _speechToText.isListening;

  /// Main Parsing Logic
  VoiceParsedExpense? parseVoiceInput(String text) {
    try {
      // 1. Normalize Text (Gujarati digits -> English, lowercase)
      String normalizedText = _normalizeText(text);

      // 2. Extract Amount
      final amount = _extractAmount(normalizedText);
      if (amount == null || amount <= 0) return null;

      // 3. Extract Category
      final category = _extractCategory(normalizedText);

      // 4. Extract Date
      final date = _extractDate(normalizedText);

      // 5. Extract Merchant
      final merchant = _extractMerchant(normalizedText);

      // 6. Extract Title
      final title = _extractTitle(text, amount); 

      return VoiceParsedExpense(
        amount: amount,
        category: category,
        title: title,
        date: date,
        merchantName: merchant,
        rawText: text,
      );
    } catch (e) {
      print('Parsing Error: $e');
      return null;
    }
  }

  String _normalizeText(String text) {
    String res = text.toLowerCase();
    _digitMap.forEach((gu, en) {
      res = res.replaceAll(gu, en);
    });
    return res;
  }

  double? _extractAmount(String text) {
    // Check for "k" notation first e.g. "5k" -> 5000
    // Regex handles digits with optional 'k'
    final match = _patterns['amount']!.firstMatch(text);
    if (match != null) {
      String rawAmt = match.group(1)!.replaceAll(',', '');
      double multiplier = 1.0;
      
      if (rawAmt.endsWith('k')) {
        multiplier = 1000.0;
        rawAmt = rawAmt.substring(0, rawAmt.length - 1);
      }
      
      final val = double.tryParse(rawAmt);
      if (val != null) return val * multiplier;
    }
    return null; // Could allow word-parsing fallback if needed
  }

  String _extractCategory(String text) {
    if (_patterns['cat_food']!.hasMatch(text)) return 'food';
    if (_patterns['cat_transport']!.hasMatch(text)) return 'transport';
    if (_patterns['cat_shopping']!.hasMatch(text)) return 'shopping';
    if (_patterns['cat_groceries']!.hasMatch(text)) return 'groceries';
    if (_patterns['cat_bills']!.hasMatch(text)) return 'bills';
    if (_patterns['cat_entertainment']!.hasMatch(text)) return 'entertainment';
    if (_patterns['cat_health']!.hasMatch(text)) return 'health';
    if (_patterns['cat_education']!.hasMatch(text)) return 'education';
    
    return 'others';
  }

  DateTime _extractDate(String text) {
    final now = DateTime.now();
    if (_patterns['yesterday']!.hasMatch(text)) {
      return now.subtract(const Duration(days: 1));
    }
    return now; // Default to today
  }

  String? _extractMerchant(String text) {
    // Pattern 1: English (at/to/from Name)
    final engPattern = RegExp(r'(?:at|to|from)\s+([A-Za-z][A-Za-z0-9\s&]+)', caseSensitive: false);
    final engMatch = engPattern.firstMatch(text);
    if (engMatch != null) return engMatch.group(1)?.trim();

    // Pattern 2: Gujarati (Name ne apya / Name pase thi)
    // "Rahul ne apya", "Rahul pasethi lidha"
    final gujPattern = RegExp(r'(\S+)\s+(?:ne|pase\s*thi|પાસેથી|ને|પાસેથી)\b', caseSensitive: false);
    final gujMatch = gujPattern.firstMatch(text);
    if (gujMatch != null) return gujMatch.group(1)?.trim();

    return null;
  }

  String _extractTitle(String text, double amount) {
    // Simple heuristic: Take the original text, usually it's short enough to be the title too.
    // Or just a standard format.
    // Let's return the Capitalized text for now, maybe stripping amount if convenient.
    return text[0].toUpperCase() + text.substring(1);
  }

  Expense toExpense(VoiceParsedExpense parsed) {
    return Expense(
      title: parsed.title,
      amount: parsed.amount,
      category: parsed.category,
      date: parsed.date,
      notes: 'Voice: ${parsed.rawText}',
      source: 'voice',
      merchantName: parsed.merchantName,
      createdAt: DateTime.now(),
    );
  }

  List<String> getQuickCommands() {
    return [
      '500 for lunch (૫૦૦ જમવાના)',
      '1.5k shopping (૧.૫k ખરીદી)',
      'Auto fare 200 (રિક્ષા ભાડું ૨૦૦)',
      'Yesterday 500 petrol (ગઈકાલે પ પેટ્રોલ)',
    ];
  }
  void dispose() {
    _speechToText.cancel();
  }
}

class VoiceParsedExpense {
  final double amount;
  final String category;
  final String title;
  final DateTime date;
  final String rawText;
  final String? merchantName;

  VoiceParsedExpense({
    required this.amount,
    required this.category,
    required this.title,
    required this.date,
    this.merchantName,
    required this.rawText,
  });

  bool get isValid => amount > 0 && title.isNotEmpty;
}
