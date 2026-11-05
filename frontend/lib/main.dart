import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/budget_viewmodel.dart';
import 'viewmodels/category_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/report_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/transaction_viewmodel.dart';

import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/budgets/budgets_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/expenses/expenses_view.dart';
import 'views/income/income_view.dart';
import 'views/profile/profile_view.dart';
import 'views/reports/reports_view.dart';
import 'views/shell/app_shell.dart';
import 'views/transactions/transactions_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageManager.ensureInitialized();
  runApp(const ExpenseFlowApp());
}

class ExpenseFlowApp extends StatelessWidget {
  const ExpenseFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => TransactionViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => BudgetViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
      ],
      child: const ExpenseFlowMaterialApp(),
    );
  }
}

class ExpenseFlowMaterialApp extends StatefulWidget {
  const ExpenseFlowMaterialApp({super.key});

  @override
  State<ExpenseFlowMaterialApp> createState() => _ExpenseFlowMaterialAppState();
}

class _ExpenseFlowMaterialAppState extends State<ExpenseFlowMaterialApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authVm = context.read<AuthViewModel>();

    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: authVm,
      redirect: (context, state) {
        if (!authVm.isInitialized) return null;

        final isLoggedIn = authVm.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }
        if (isLoggedIn && isAuthRoute) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterView(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(
              location: state.matchedLocation,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardView(),
            ),
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsView(),
            ),
            GoRoute(
              path: '/income',
              builder: (context, state) => const IncomeView(),
            ),
            GoRoute(
              path: '/expenses',
              builder: (context, state) => const ExpensesView(),
            ),
            GoRoute(
              path: '/budgets',
              builder: (context, state) => const BudgetsView(),
            ),
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsView(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileView(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeVm = context.watch<ThemeViewModel>();

    return MaterialApp.router(
      title: 'ExpenseFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeVm.themeMode,
      routerConfig: _router,
    );
  }
}
