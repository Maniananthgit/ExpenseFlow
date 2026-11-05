import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/category_viewmodel.dart';
import '../../viewmodels/transaction_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/transaction_tile.dart';
import 'add_edit_transaction_dialog.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionViewModel>().fetchTransactions(page: 1);
      context.read<CategoryViewModel>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final txVm = context.read<TransactionViewModel>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (range != null) {
      txVm.setDateRange(
        DateFormatter.formatApi(range.start),
        DateFormatter.formatApi(range.end),
      );
    }
  }

  Future<void> _confirmDelete(TransactionModel tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txVm = context.watch<TransactionViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final currency = authVm.currentUser?.currency ?? 'INR';

    return Scaffold(
      body: Column(
        children: [
          // Header & Filters Section
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transactions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${txVm.total} total transactions found',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => AddEditTransactionDialog.show(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('New Transaction'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar & Date Filter Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (val) => txVm.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Search by description or category...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    txVm.setSearchQuery(null);
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: Text(
                        txVm.startDate != null ? 'Filtered Date' : 'Filter Date',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (txVm.startDate != null || txVm.selectedType != null || txVm.searchQuery != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Reset Filters',
                        icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          txVm.resetFilters();
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Segment Chips (All / Expense / Income)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null, txVm),
                      const SizedBox(width: 8),
                      _buildFilterChip('Expenses Only', 'EXPENSE', txVm, color: AppColors.expense),
                      const SizedBox(width: 8),
                      _buildFilterChip('Income Only', 'INCOME', txVm, color: AppColors.income),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transactions List Body
          Expanded(
            child: txVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : txVm.transactions.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'No Transactions Found',
                        message: 'Try adjusting your filters or record a new transaction.',
                        buttonText: 'Add First Transaction',
                        onButtonPressed: () => AddEditTransactionDialog.show(context),
                      )
                    : RefreshIndicator(
                        onRefresh: () => txVm.fetchTransactions(page: txVm.currentPage),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
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
                      ),
          ),

          // Pagination Bar
          if (txVm.totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${txVm.currentPage} of ${txVm.totalPages}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: txVm.currentPage > 1
                            ? () => txVm.fetchTransactions(page: txVm.currentPage - 1)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: txVm.currentPage < txVm.totalPages
                            ? () => txVm.fetchTransactions(page: txVm.currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? type,
    TransactionViewModel txVm, {
    Color? color,
  }) {
    final isSelected = txVm.selectedType == type;
    final effectiveColor = color ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => txVm.setFilterType(type),
      selectedColor: effectiveColor.withOpacity(0.18),
      checkmarkColor: effectiveColor,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? effectiveColor : null,
      ),
    );
  }
}

