import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../transactions/add_edit_transaction_dialog.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  int _calculateSelectedIndex(BuildContext context) {
    if (location == '/') return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/income')) return 2;
    if (location.startsWith('/expenses')) return 3;
    if (location.startsWith('/budgets')) return 4;
    if (location.startsWith('/reports')) return 5;
    if (location.startsWith('/profile')) return 6;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/income');
        break;
      case 3:
        context.go('/expenses');
        break;
      case 4:
        context.go('/budgets');
        break;
      case 5:
        context.go('/reports');
        break;
      case 6:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeVm = context.watch<ThemeViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final selectedIndex = _calculateSelectedIndex(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'ExpenseFlow',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => themeVm.toggleTheme(),
          ),
          // User Avatar
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  authVm.currentUser?.fullName.isNotEmpty == true
                      ? authVm.currentUser!.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddEditTransactionDialog.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Transaction', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (idx) => _onItemTapped(idx, context),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                      label: Text('Transactions'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.trending_up_outlined),
                      selectedIcon: Icon(Icons.trending_up_rounded, color: AppColors.income),
                      label: Text('Income'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.trending_down_outlined),
                      selectedIcon: Icon(Icons.trending_down_rounded, color: AppColors.expense),
                      label: Text('Expenses'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pie_chart_outline_rounded),
                      selectedIcon: Icon(Icons.pie_chart_rounded, color: AppColors.primary),
                      label: Text('Budgets'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.insert_chart_outlined_rounded),
                      selectedIcon: Icon(Icons.insert_chart_rounded, color: AppColors.primary),
                      label: Text('Reports'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex > 4 ? 0 : selectedIndex,
              onTap: (idx) {
                if (idx == 4) {
                  // Show modal sheet with remaining options or go to Budgets
                  context.go('/budgets');
                } else {
                  _onItemTapped(idx, context);
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: 'Transactions',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.trending_up_rounded),
                  label: 'Income',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.trending_down_rounded),
                  label: 'Expenses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart_rounded),
                  label: 'Budgets',
                ),
              ],
            ),
    );
  }
}

