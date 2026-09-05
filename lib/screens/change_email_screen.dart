import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});
  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;

  Future<void> _handleRequestOtp() async {
    if (_newEmailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.requestEmailChangeOtp(_newEmailController.text.trim(), _passwordController.text);
    setState(() => _loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.success) {
      setState(() => _otpSent = true);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the code')));
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.verifyEmailChangeOtp(_otpController.text.trim());
    setState(() => _loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: const Text('Change Email', style: TextStyle(color: AppColors.textPrimary))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _otpSent ? _buildOtpStep() : _buildRequestStep(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRequestStep() {
    return [
      TextField(
        controller: _newEmailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: _inputDecoration('New Email', Icons.email_outlined),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordController,
        obscureText: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: _inputDecoration('Current Password', Icons.lock_outline),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: _loading ? null : _handleRequestOtp,
          child: _loading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Send Verification Code'),
        ),
      ),
    ];
  }

  List<Widget> _buildOtpStep() {
    return [
      Text(
        'Enter the code sent to ${_newEmailController.text.trim()}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: _inputDecoration('Verification Code', Icons.verified_outlined),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: _loading ? null : _handleVerifyOtp,
          child: _loading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Verify & Update Email'),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: _loading ? null : () => setState(() => _otpSent = false),
        child: const Text('Change email address', style: TextStyle(color: AppColors.textSecondary)),
      ),
    ];
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }
}
