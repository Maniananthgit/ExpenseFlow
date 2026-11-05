import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/transaction_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_edit_transaction_dialog.dart';

class IncomeView extends StatefulWidget {
  const IncomeView({super.key});

  @override
  State<IncomeView> createState() => _IncomeViewState();
}

class _IncomeViewState extends State<IncomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionViewModel>().fetchTransactions(page: 1, overrideType: 'INCOME');
      context.read<DashboardViewModel>().fetchDashboardData();
    });
  }

  Future<void> _confirmDelete(TransactionModel tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income Record?'),
        content: Text('Are you sure you want to delete "${tx.description ?? tx.category?.name}"?'),
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
      final success = await context.read<TransactionViewModel>().deleteTransaction(tx.id);
      if (success && mounted) {
        context.read<DashboardViewModel>().fetchDashboardData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txVm = context.watch<TransactionViewModel>();
    final dashVm = context.watch<DashboardViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final currency = authVm.currentUser?.currency ?? 'INR';

    final totalIncome = dashVm.summary?.totalIncome ?? 0.0;
    final monthlyIncome = dashVm.summary?.monthlyIncome ?? 0.0;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track all earnings, salary, and incoming cashflow',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => AddEditTransactionDialog.show(context, initialType: 'INCOME'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Income'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.income,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top Stat Cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Lifetime Income',
                    amount: CurrencyFormatter.format(totalIncome, currency: currency),
                    subtitle: 'Cumulative all-time income',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StatCard(
                    title: 'Current Month Income',
                    amount: CurrencyFormatter.format(monthlyIncome, currency: currency),
                    subtitle: 'Earnings for this month',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Income History Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (txVm.isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                    else if (txVm.transactions.isEmpty)
                      EmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'No Income Records Yet',
                        message: 'Add your salary, freelancing, or other income sources.',
                        buttonText: 'Add First Income',
                        onButtonPressed: () => AddEditTransactionDialog.show(context, initialType: 'INCOME'),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: txVm.transactions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = txVm.transactions[index];
                          return TransactionTile(
                            transaction: tx,
                            currency: currency,
                            onEdit: () => AddEditTransactionDialog.show(context, transaction: tx),
                            onDelete: () => _confirmDelete(tx),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

