import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'change_email_screen.dart';
import 'subscription_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await StorageService.getUserName();
    final email = await StorageService.getUserEmail();
    setState(() {
      _name = name ?? '';
      _email = email ?? '';
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Logout', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: AppColors.sell))),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  CircleAvatar(radius: 26, backgroundColor: AppColors.primary, child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.background, fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(_email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Subscription', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _settingsTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Manage Plan',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
            ),
            const SizedBox(height: 24),
            const Text('Security', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _settingsTile(
              icon: Icons.email_outlined,
              title: 'Change Email',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangeEmailScreen())),
            ),
            const SizedBox(height: 24),
            _settingsTile(
              icon: Icons.logout,
              title: 'Logout',
              iconColor: AppColors.sell,
              titleColor: AppColors.sell,
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppColors.textPrimary,
    Color titleColor = AppColors.textPrimary,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: TextStyle(color: titleColor, fontSize: 15))),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
