import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/category_viewmodel.dart';
import '../../viewmodels/transaction_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddEditTransactionDialog extends StatefulWidget {
  final TransactionModel? transaction;
  final String? initialType;

  const AddEditTransactionDialog({
    super.key,
    this.transaction,
    this.initialType,
  });

  static Future<bool?> show(
    BuildContext context, {
    TransactionModel? transaction,
    String? initialType,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditTransactionDialog(
        transaction: transaction,
        initialType: initialType,
      ),
    );
  }

  @override
  State<AddEditTransactionDialog> createState() => _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState extends State<AddEditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  String? _selectedCategoryId;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _selectedType = t?.type ?? widget.initialType ?? 'EXPENSE';
    _selectedCategoryId = t?.categoryId;
    _amountController = TextEditingController(text: t != null ? t.amount.toString() : '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _selectedDate = t?.transactionDate ?? DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryViewModel>().fetchCategories(type: _selectedType);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _selectedType = newType;
      _selectedCategoryId = null;
    });
    context.read<CategoryViewModel>().fetchCategories(type: newType);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final txVm = context.read<TransactionViewModel>();
    final dashVm = context.read<DashboardViewModel>();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    bool success;
    if (widget.transaction != null) {
      success = await txVm.updateTransaction(
        id: widget.transaction!.id,
        categoryId: _selectedCategoryId,
        amount: amount,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        transactionDate: DateFormatter.formatApi(_selectedDate),
      );
    } else {
      success = await txVm.createTransaction(
        categoryId: _selectedCategoryId!,
        amount: amount,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        transactionDate: DateFormatter.formatApi(_selectedDate),
      );
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      dashVm.fetchDashboardData();
      Navigator.of(context).pop(true);
    } else if (mounted && txVm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(txVm.errorMessage!),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catVm = context.watch<CategoryViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final currency = authVm.currentUser?.currency ?? 'INR';
    final isIncome = _selectedType == 'INCOME';

    final categories = isIncome ? catVm.incomeCategories : catVm.expenseCategories;

    // Default select first category if current is null or not in list
    if (categories.isNotEmpty &&
        (_selectedCategoryId == null || !categories.any((c) => c.id == _selectedCategoryId))) {
      _selectedCategoryId = categories.first.id;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.transaction != null ? 'Edit Transaction' : 'Add Transaction',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Segmented Type Toggle (Income / Expense)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _onTypeChanged('EXPENSE'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isIncome ? AppColors.expense : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Expense',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: !isIncome ? Colors.white : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _onTypeChanged('INCOME'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isIncome ? AppColors.income : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Income',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isIncome ? Colors.white : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount
                  CustomTextField(
                    controller: _amountController,
                    label: 'Amount (${CurrencyFormatter.getSymbol(currency)})',
                    hint: '0.00',
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter amount';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0) return 'Enter a valid positive amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        items: categories.map((CategoryModel cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Row(
                              children: [
                                Icon(cat.iconData, color: cat.color, size: 20),
                                const SizedBox(width: 10),
                                Text(cat.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategoryId = val);
                        },
                        decoration: const InputDecoration(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date Picker Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Date',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormatter.formatDisplay(_selectedDate),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  CustomTextField(
                    controller: _descriptionController,
                    label: 'Description / Note',
                    hint: 'e.g., Grocery shopping at Trader Joe\'s',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      CustomButton(
                        text: widget.transaction != null ? 'Update' : 'Add Transaction',
                        isLoading: _isSaving,
                        onPressed: _saveTransaction,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

