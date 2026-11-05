import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/dashboard_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/empty_state.dart';
import '../transactions/add_edit_transaction_dialog.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().fetchDashboardData();
      context.read<BudgetViewModel>().fetchBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashVm = context.watch<DashboardViewModel>();
    final budgetVm = context.watch<BudgetViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final currency = authVm.currentUser?.currency ?? 'INR';
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;
    final isTablet = width >= 650 && width < 1000;

    if (dashVm.isLoading && dashVm.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = dashVm.summary;
    if (summary == null) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Dashboard',
        message: dashVm.errorMessage ?? 'Please check your connection and try again.',
        buttonText: 'Retry',
        onButtonPressed: () => dashVm.fetchDashboardData(),
      );
    }

    final exceededBudgets = budgetVm.exceededBudgets;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          dashVm.fetchDashboardData(),
          budgetVm.fetchBudgets(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${authVm.currentUser?.fullName.split(' ').first ?? 'User'} 👋',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is your financial summary for this month',
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
                  label: const Text('Add Transaction'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Budget Exceeded Alert Banner
            if (exceededBudgets.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.expense.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.expense.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget Alert (${exceededBudgets.length} exceeded)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.expense,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You have exceeded the budget limit for ${exceededBudgets.map((b) => b.category?.name ?? 'Category').join(', ')}.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/budgets'),
                      child: const Text('Manage Budgets', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],

            // 4 KPI Summary Cards
            _buildStatCardsGrid(summary, currency, isDesktop, isTablet),
            const SizedBox(height: 24),

            // Charts Section (Income vs Expense Trends & Category Breakdown)
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildMonthlyTrendChart(dashVm.trends, currency, isDark)),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _buildCategoryBreakdownCard(dashVm.categoryBreakdown, currency, isDark),
                  ),
                ],
              )
            else ...[
              _buildMonthlyTrendChart(dashVm.trends, currency, isDark),
              const SizedBox(height: 20),
              _buildCategoryBreakdownCard(dashVm.categoryBreakdown, currency, isDark),
            ],
            const SizedBox(height: 24),

            // Recent Transactions Card
            _buildRecentTransactionsCard(summary.recentTransactions, currency, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardsGrid(
    DashboardSummaryModel summary,
    String currency,
    bool isDesktop,
    bool isTablet,
  ) {
    final cards = [
      StatCard(
        title: 'Current Balance',
        amount: CurrencyFormatter.format(summary.currentBalance, currency: currency),
        subtitle: 'Lifetime net savings',
        icon: Icons.account_balance_rounded,
        color: AppColors.primary,
      ),
      StatCard(
        title: 'Total Income',
        amount: CurrencyFormatter.format(summary.totalIncome, currency: currency),
        subtitle: 'Monthly: ${CurrencyFormatter.format(summary.monthlyIncome, currency: currency)}',
        icon: Icons.trending_up_rounded,
        color: AppColors.income,
      ),
      StatCard(
        title: 'Total Expenses',
        amount: CurrencyFormatter.format(summary.totalExpenses, currency: currency),
        subtitle: 'Monthly: ${CurrencyFormatter.format(summary.monthlySpending, currency: currency)}',
        icon: Icons.trending_down_rounded,
        color: AppColors.expense,
      ),
      StatCard(
        title: 'Monthly Savings',
        amount: CurrencyFormatter.format(summary.monthlySavings, currency: currency),
        subtitle: 'Savings Rate: ${summary.savingsRate}%',
        icon: Icons.savings_rounded,
        color: summary.monthlySavings >= 0 ? AppColors.income : AppColors.expense,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
        ],
      );
    } else {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
      );
    }
  }

  Widget _buildMonthlyTrendChart(
    List<MonthlyTrendItemModel> trends,
    String currency,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                      'Income vs Expense Trends',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '12-Month financial performance',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _chartLegend('Income', AppColors.income),
                    const SizedBox(width: 14),
                    _chartLegend('Expense', AppColors.expense),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxTrend(trends),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final type = rodIndex == 0 ? 'Income' : 'Expense';
                        return BarTooltipItem(
                          '$type\n${CurrencyFormatter.format(rod.toY, currency: currency)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < trends.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                trends[idx].monthName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: trends.asMap().entries.map((e) {
                    final idx = e.key;
                    final t = e.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: t.income,
                          color: AppColors.income,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: t.expense,
                          color: AppColors.expense,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMaxTrend(List<MonthlyTrendItemModel> trends) {
    double m = 1000.0;
    for (final t in trends) {
      if (t.income > m) m = t.income;
      if (t.expense > m) m = t.expense;
    }
    return m * 1.15;
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard(
    DashboardCategoryBreakdownModel? breakdown,
    String currency,
    bool isDark,
  ) {
    final expenses = breakdown?.expenseCategories ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Current month expense distribution',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),

            if (expenses.isEmpty)
              const SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'No expenses recorded this month.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: expenses.take(5).map((e) {
                      Color col;
                      try {
                        final hex = e.categoryColor.replaceAll('#', '');
                        col = Color(int.parse('FF$hex', radix: 16));
                      } catch (_) {
                        col = AppColors.primary;
                      }
                      return PieChartSectionData(
                        value: e.totalAmount,
                        title: '${e.percentage.toInt()}%',
                        color: col,
                        radius: 35,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...expenses.take(4).map((e) {
                Color col;
                try {
                  final hex = e.categoryColor.replaceAll('#', '');
                  col = Color(int.parse('FF$hex', radix: 16));
                } catch (_) {
                  col = AppColors.primary;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.categoryName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(e.totalAmount, currency: currency),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsCard(
    List<dynamic> recentTransactions,
    String currency,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Latest recorded financial activity',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/transactions'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentTransactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No transactions recorded yet.'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentTransactions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final t = recentTransactions[index];
                  return TransactionTile(
                    transaction: t,
                    currency: currency,
                    onEdit: () => AddEditTransactionDialog.show(context, transaction: t),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

