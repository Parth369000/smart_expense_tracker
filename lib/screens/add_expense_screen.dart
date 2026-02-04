import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/expense_bloc.dart';
import '../models/expense_model.dart';
import '../services/receipt_scanner_service.dart';
import '../services/voice_input_service.dart';
import '../theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  final String? source;

  const AddExpenseScreen({
    Key? key,
    this.expense,
    this.source,
  }) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _merchantController = TextEditingController();

  String _selectedCategory = 'others';
  String _selectedType = 'debit'; // 'debit' or 'credit'
  DateTime _selectedDate = DateTime.now();
  List<ExpenseCategory> _categories = [];
  bool _isLoading = false;
  bool _isListening = false;

  final ReceiptScannerService _receiptService = ReceiptScannerService();
  final VoiceInputService _voiceService = VoiceInputService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    if (widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toString();
      _notesController.text = widget.expense!.notes ?? '';
      _merchantController.text = widget.expense!.merchantName ?? '';
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
      _selectedType = widget.expense!.type;
    } else if (widget.source == 'receipt') {
      _scanReceipt();
    } else if (widget.source == 'voice') {
      _startVoiceInput();
    }
  }

  void _loadCategories() {
    context.read<ExpenseBloc>().add(const LoadCategories());
  }

  Future<void> _scanReceipt() async {
    setState(() => _isLoading = true);
    
    final image = await _receiptService.captureImage();
    if (image != null) {
      final receipt = await _receiptService.scanReceipt(image);
      if (receipt != null && receipt.isValid) {
        setState(() {
          _amountController.text = receipt.amount!.toString();
          _merchantController.text = receipt.merchantName ?? '';
          _titleController.text = receipt.merchantName ?? 'Receipt Expense';
          _selectedCategory = receipt.category;
          if (receipt.date != null) {
            _selectedDate = receipt.date!;
          }
          _notesController.text = 'Scanned from receipt';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt scanned successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not extract data from receipt')),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _startVoiceInput() async {
    final available = await _voiceService.isAvailable();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice input not available')),
      );
      return;
    }

    setState(() => _isListening = true);

    await _voiceService.startListening(
      onResult: (text) {
        final parsed = _voiceService.parseVoiceInput(text);
        if (parsed != null && parsed.isValid) {
          setState(() {
            _amountController.text = parsed.amount.toString();
            _titleController.text = parsed.title;
            _merchantController.text = parsed.merchantName ?? '';
            _selectedCategory = parsed.category;
            _selectedDate = parsed.date;
            _notesController.text = 'Added via voice: "${parsed.rawText}"';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice input: "${parsed.rawText}"')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not understand voice input')),
          );
        }
      },
      onDone: () {
        setState(() => _isListening = false);
      },
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;

    final expense = Expense(
      id: widget.expense?.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
      source: widget.expense?.source ?? widget.source ?? 'manual',
      merchantName: _merchantController.text.trim().isEmpty 
          ? null 
          : _merchantController.text.trim(),
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
      type: _selectedType,
    );

    if (widget.expense != null) {
      context.read<ExpenseBloc>().add(UpdateExpense(expense));
    } else {
      context.read<ExpenseBloc>().add(AddExpense(expense));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense != null ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (widget.source == 'receipt' || widget.source == 'voice')
            IconButton(
              onPressed: widget.source == 'receipt' ? _scanReceipt : _startVoiceInput,
              icon: Icon(
                widget.source == 'receipt' ? Icons.camera_alt : Icons.mic,
              ),
            ),
        ],
      ),
      body: BlocListener<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state.categories.isNotEmpty) {
            setState(() => _categories = state.categories);
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Top Section: Toggle & Amount
                    Container(
                      padding: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            offset: const Offset(0, 4),
                            blurRadius: 16,
                          ),
                        ],
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Type Toggle
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 48),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                _buildToggleOption('Debit', 'debit'),
                                _buildToggleOption('Credit', 'credit'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Amount Input
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                Text(
                                  'Enter Amount',
                                  style: TextStyle(
                                    color: AppTheme.onSurfaceLight,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedType == 'credit' 
                                        ? AppTheme.secondaryColor 
                                        : AppTheme.primaryColor,
                                    height: 1.1,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[300],
                                    ),
                                    prefix: Text(
                                      '₹',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedType == 'credit' 
                                            ? AppTheme.secondaryColor 
                                            : AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (double.tryParse(value) == null) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Voice Indicator
                    if (_isListening)
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic, color: AppTheme.accentColor),
                              const SizedBox(width: 8),
                              const Text('Listening...', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                         ),
                       ),

                    // Form Fields
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Split into categories',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.onSurfaceLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Category Selector
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _categories.map((category) {
                                  final isSelected = _selectedCategory == category.id;
                                  final color = Color(category.color);
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedCategory = category.id),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 16),
                                      child: Column(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isSelected ? color : color.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                              boxShadow: isSelected ? [
                                                BoxShadow(
                                                  color: color.withOpacity(0.4),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ] : [],
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(category.icon),
                                              color: isSelected ? Colors.white : color,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            category.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? AppTheme.onSurface : AppTheme.onSurfaceLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Details Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      labelText: 'What is this for?',
                                      prefixIcon: Icon(Icons.title),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Divider(color: Colors.grey[100], height: 32),
                                  InkWell(
                                    onTap: _selectDate,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          DateFormat('EEEE, dd MMM').format(_selectedDate),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                  Divider(color: Colors.grey[100], height: 32),
                                  TextFormField(
                                    controller: _merchantController,
                                    decoration: const InputDecoration(
                                      labelText: 'Merchant (Optional)',
                                      prefixIcon: Icon(Icons.store),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Divider(color: Colors.grey[100], height: 32),
                                  TextFormField(
                                    controller: _notesController,
                                    decoration: const InputDecoration(
                                      labelText: 'Notes (Optional)',
                                      prefixIcon: Icon(Icons.notes),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveExpense,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedType == 'credit' 
                                      ? AppTheme.secondaryColor 
                                      : AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: (_selectedType == 'credit' 
                                      ? AppTheme.secondaryColor 
                                      : AppTheme.primaryColor).withOpacity(0.4),
                                ),
                                child: Text(
                                  widget.expense != null ? 'Update Transaction' : 'Save Transaction',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildToggleOption(String label, String value) {
    final isSelected = _selectedType == value;
    final color = value == 'credit' ? AppTheme.secondaryColor : AppTheme.primaryColor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? color : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_bag': Icons.shopping_bag,
      'movie': Icons.movie,
      'receipt': Icons.receipt,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'flight': Icons.flight,
      'local_grocery_store': Icons.local_grocery_store,
      'more_horiz': Icons.more_horiz,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _merchantController.dispose();
    _receiptService.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}
