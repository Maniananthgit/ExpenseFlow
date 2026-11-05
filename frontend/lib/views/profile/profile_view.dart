import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String _selectedCurrency;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _selectedCurrency = user?.currency ?? 'INR';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isUpdatingProfile = true);

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.updateProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      currency: _selectedCurrency,
    );

    setState(() => _isUpdatingProfile = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } else if (mounted && authVm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVm.errorMessage!), backgroundColor: AppColors.expense),
      );
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isChangingPassword = true);

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    setState(() => _isChangingPassword = false);

    if (success && mounted) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!')),
      );
    } else if (mounted && authVm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVm.errorMessage!), backgroundColor: AppColors.expense),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of ExpenseFlow?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthViewModel>().logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authVm = context.watch<AuthViewModel>();
    final themeVm = context.watch<ThemeViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile & Account Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage your personal details, preferences, and security',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),

              // Profile Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _profileFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: Text(
                                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'User',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.email ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.isEmpty ? 'Name cannot be empty' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Display Currency',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              items: const [
                                DropdownMenuItem(value: 'INR', child: Text('INR (₹) - Indian Rupee')),
                                DropdownMenuItem(value: 'USD', child: Text('USD (\$) - US Dollar')),
                                DropdownMenuItem(value: 'EUR', child: Text('EUR (€) - Euro')),
                                DropdownMenuItem(value: 'GBP', child: Text('GBP (£) - British Pound')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCurrency = val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CustomButton(
                            text: 'Save Changes',
                            isLoading: _isUpdatingProfile,
                            onPressed: _updateProfile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Appearance Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDark ? 'Dark theme enabled' : 'Light theme enabled',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: themeVm.isDarkMode,
                        onChanged: (_) => themeVm.toggleTheme(),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Security & Password Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security & Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _currentPasswordController,
                          label: 'Current Password',
                          obscureText: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          validator: (v) => v == null || v.isEmpty ? 'Enter current password' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          obscureText: true,
                          prefixIcon: Icons.lock_reset_rounded,
                          validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CustomButton(
                            text: 'Update Password',
                            isLoading: _isChangingPassword,
                            onPressed: _changePassword,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.expense),
                  label: const Text('Sign Out of ExpenseFlow', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.expense),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

