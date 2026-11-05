import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/report_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../widgets/stat_card.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().fetchReport();
    });
  }

  Future<void> _handleCsvExport() async {
    final reportVm = context.read<ReportViewModel>();
    final csvData = await reportVm.exportTransactionsCsv();

    if (csvData != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.file_download_done_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('CSV Export Ready'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transactions have been exported in RFC 4180 CSV format.'),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvData,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy to Clipboard'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csvData));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copied to clipboard!')),
                );
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportVm = context.watch<ReportViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final currency = authVm.currentUser?.currency ?? 'INR';
    final isYearly = reportVm.isYearlyView;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with CSV Export button and Monthly/Yearly Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Reports & Analytics',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isYearly
                          ? 'Yearly statement for ${reportVm.selectedYear}'
                          : DateFormatter.formatMonthYear(reportVm.selectedMonth, reportVm.selectedYear),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Segmented Button
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Monthly')),
                        ButtonSegment(value: true, label: Text('Yearly')),
                      ],
                      selected: {isYearly},
                      onSelectionChanged: (set) => reportVm.toggleViewMode(set.first),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _handleCsvExport,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Export CSV'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (reportVm.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (!isYearly && reportVm.monthlyReport != null)
              _buildMonthlyReport(reportVm.monthlyReport!, currency, isDark)
            else if (isYearly && reportVm.yearlyReport != null)
              _buildYearlyReport(reportVm.yearlyReport!, currency, isDark)
            else
              const Center(child: Text('No data found for this period.')),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyReport(MonthlyReportModel rep, String currency, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Summary
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Monthly Income',
                amount: CurrencyFormatter.format(rep.totalIncome, currency: currency),
                subtitle: 'Total incoming funds',
                icon: Icons.trending_up_rounded,
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Total Monthly Expenses',
                amount: CurrencyFormatter.format(rep.totalExpense, currency: currency),
                subtitle: 'Total outgoing funds',
                icon: Icons.trending_down_rounded,
                color: AppColors.expense,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Net Monthly Savings',
                amount: CurrencyFormatter.format(rep.netSavings, currency: currency),
                subtitle: 'Savings Rate: ${rep.savingsRate}%',
                icon: Icons.savings_rounded,
                color: rep.netSavings >= 0 ? AppColors.income : AppColors.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Category Breakdown Card & Top Expenses
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category-wise Expense Breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (rep.categoryBreakdown.isEmpty)
                        const Text('No expenses recorded for this month.')
                      else
                        ...rep.categoryBreakdown.map((cat) {
                          Color col;
                          try {
                            final hex = cat.categoryColor.replaceAll('#', '');
                            col = Color(int.parse('FF$hex', radix: 16));
                          } catch (_) {
                            col = AppColors.primary;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          cat.categoryName,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${CurrencyFormatter.format(cat.totalAmount, currency: currency)} (${cat.percentage}%)',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: cat.percentage / 100.0,
                                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(col),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Expenses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (rep.topExpenses.isEmpty)
                        const Text('No expenses recorded.')
                      else
                        ...rep.topExpenses.map((t) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.expense.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.expense),
                            ),
                            title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${t.category} • ${t.date}'),
                            trailing: Text(
                              CurrencyFormatter.format(t.amount, currency: currency),
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.expense),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearlyReport(YearlyReportModel rep, String currency, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Yearly Income',
                amount: CurrencyFormatter.format(rep.totalIncome, currency: currency),
                subtitle: 'Full year revenue',
                icon: Icons.trending_up_rounded,
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Total Yearly Expenses',
                amount: CurrencyFormatter.format(rep.totalExpense, currency: currency),
                subtitle: 'Full year expenditures',
                icon: Icons.trending_down_rounded,
                color: AppColors.expense,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Net Yearly Savings',
                amount: CurrencyFormatter.format(rep.netSavings, currency: currency),
                subtitle: 'Annual savings rate: ${rep.savingsRate}%',
                icon: Icons.savings_rounded,
                color: rep.netSavings >= 0 ? AppColors.income : AppColors.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '12-Month Performance Table (${rep.year})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Month')),
                    DataColumn(label: Text('Income')),
                    DataColumn(label: Text('Expense')),
                    DataColumn(label: Text('Net Savings')),
                  ],
                  rows: rep.monthlyTrends.map((m) {
                    return DataRow(
                      cells: [
                        DataCell(Text(m.monthName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(
                          CurrencyFormatter.format(m.income, currency: currency),
                          style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.w600),
                        )),
                        DataCell(Text(
                          CurrencyFormatter.format(m.expense, currency: currency),
                          style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600),
                        )),
                        DataCell(Text(
                          CurrencyFormatter.format(m.netSavings, currency: currency),
                          style: TextStyle(
                            color: m.netSavings >= 0 ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.w700,
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
