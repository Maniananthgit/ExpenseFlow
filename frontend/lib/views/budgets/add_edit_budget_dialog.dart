import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../viewmodels/category_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddEditBudgetDialog extends StatefulWidget {
  final BudgetModel? budget;

  const AddEditBudgetDialog({super.key, this.budget});

  static Future<bool?> show(BuildContext context, {BudgetModel? budget}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditBudgetDialog(budget: budget),
    );
  }

  @override
  State<AddEditBudgetDialog> createState() => _AddEditBudgetDialogState();
}

class _AddEditBudgetDialogState extends State<AddEditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategoryId;
  late TextEditingController _amountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _selectedCategoryId = b?.categoryId;
    _amountController = TextEditingController(text: b != null ? b.amount.toString() : '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryViewModel>().fetchCategories(type: 'EXPENSE');
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expense category'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final budgetVm = context.read<BudgetViewModel>();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    bool success;
    if (widget.budget != null) {
      success = await budgetVm.updateBudget(
        id: widget.budget!.id,
        amount: amount,
        categoryId: _selectedCategoryId,
      );
    } else {
      success = await budgetVm.createBudget(
        categoryId: _selectedCategoryId!,
        amount: amount,
      );
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else if (mounted && budgetVm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(budgetVm.errorMessage!),
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
    final categories = catVm.expenseCategories;

    if (categories.isNotEmpty &&
        (_selectedCategoryId == null || !categories.any((c) => c.id == _selectedCategoryId))) {
      _selectedCategoryId = categories.first.id;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.budget != null ? 'Edit Budget' : 'Set Category Budget',
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

                // Category Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Category',
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

                // Monthly Budget Limit
                CustomTextField(
                  controller: _amountController,
                  label: 'Monthly Limit (${CurrencyFormatter.getSymbol(currency)})',
                  hint: '5000.00',
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter budget limit';
                    final parsed = double.tryParse(v);
                    if (parsed == null || parsed <= 0) return 'Enter a valid positive number';
                    return null;
                  },
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
                      text: widget.budget != null ? 'Update Budget' : 'Save Budget',
                      isLoading: _isSaving,
                      onPressed: _saveBudget,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

