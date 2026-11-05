import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/budget_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../widgets/budget_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import 'add_edit_budget_dialog.dart';

class BudgetsView extends StatefulWidget {
  const BudgetsView({super.key});

  @override
  State<BudgetsView> createState() => _BudgetsViewState();
}

class _BudgetsViewState extends State<BudgetsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetViewModel>().fetchBudgets();
    });
  }

  Future<void> _confirmDelete(BudgetModel b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: Text('Are you sure you want to delete budget for "${b.category?.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<BudgetViewModel>().deleteBudget(b.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetVm = context.watch<BudgetViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final currency = authVm.currentUser?.currency ?? 'INR';
    final summary = budgetVm.summary;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Month Navigator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatMonthYear(budgetVm.selectedMonth, budgetVm.selectedYear),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => AddEditBudgetDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Set Budget'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary KPI Cards
            if (summary != null) ...[
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Budgeted',
                      amount: CurrencyFormatter.format(summary.totalBudget, currency: currency),
                      subtitle: 'Monthly planned limit',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Total Spent',
                      amount: CurrencyFormatter.format(summary.totalSpent, currency: currency),
                      subtitle: '${summary.overallUtilization}% of budget used',
                      icon: Icons.credit_card_rounded,
                      color: summary.overallUtilization > 100 ? AppColors.expense : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Remaining Budget',
                      amount: CurrencyFormatter.format(summary.totalRemaining.abs(), currency: currency),
                      subtitle: summary.totalRemaining >= 0 ? 'Safe to spend' : 'Over budget',
                      icon: Icons.savings_rounded,
                      color: summary.totalRemaining >= 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Budgets List
            if (budgetVm.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (summary == null || summary.budgets.isEmpty)
              EmptyState(
                icon: Icons.pie_chart_outline_rounded,
                title: 'No Budgets Configured',
                message: 'Keep your spending in check by setting monthly category budgets.',
                buttonText: 'Create First Budget',
                onButtonPressed: () => AddEditBudgetDialog.show(context),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 180,
                ),
                itemCount: summary.budgets.length,
                itemBuilder: (context, index) {
                  final b = summary.budgets[index];
                  return BudgetCard(
                    budget: b,
                    currency: currency,
                    onEdit: () => AddEditBudgetDialog.show(context, budget: b),
                    onDelete: () => _confirmDelete(b),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

