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
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Voice Input Indicator
                      if (_isListening)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.accentColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mic,
                                color: AppTheme.accentColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Listening... Speak your expense',
                                  style: TextStyle(
                                    color: AppTheme.accentColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Amount Field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                          prefixStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g., Lunch at restaurant',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Category Selection
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.onSurfaceLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category.id;
                          return ChoiceChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = category.id);
                              }
                            },
                            avatar: Icon(
                              _getCategoryIcon(category.icon),
                              size: 18,
                              color: isSelected 
                                  ? Colors.white 
                                  : Color(category.color),
                            ),
                            selectedColor: Color(category.color),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Date Selection
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Merchant Field
                      TextFormField(
                        controller: _merchantController,
                        decoration: const InputDecoration(
                          labelText: 'Merchant (Optional)',
                          hintText: 'e.g., Swiggy, Amazon',
                          prefixIcon: Icon(Icons.store),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Notes Field
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'Add any additional details',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveExpense,
                          child: Text(
                            widget.expense != null 
                                ? 'Update Expense' 
                                : 'Add Expense',
                          ),
                        ),
                      ),
                    ],
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
