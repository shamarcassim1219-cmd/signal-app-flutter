import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _resending = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleVerify() async {
    if (_otpController.text.trim().length != 6) {
      _showMessage('Please enter the 6-digit code');
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.verifySignup(widget.email, _otpController.text.trim());
    setState(() => _loading = false);

    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showMessage(result.message);
    }
  }

  Future<void> _handleResend() async {
    setState(() => _resending = true);
    final result = await ApiService.resendVerification(widget.email);
    setState(() => _resending = false);
    if (!mounted) return;
    _showMessage(result.message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Verify Your Email',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('We sent a 6-digit code to ${widget.email}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              const SizedBox(height: 28),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'Verification Code',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _handleVerify,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                      : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: _resending ? null : _handleResend,
                  child: Text(
                    _resending ? 'Sending...' : "Didn't get a code? Resend",
                    style: const TextStyle(color: AppColors.primary),
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
