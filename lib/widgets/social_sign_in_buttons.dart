import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';

class SocialSignInButtons extends StatelessWidget {
  final void Function(bool success, String message) onResult;
  const SocialSignInButtons({super.key, required this.onResult});

  Future<void> _handleGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // user cancelled

      final result = await ApiService.socialLogin(
        provider: 'google',
        providerUid: googleUser.id,
        email: googleUser.email,
        fullName: googleUser.displayName ?? '',
      );
      onResult(result.success, result.message);
    } catch (e) {
      onResult(false, 'Google sign-in failed. Please try again.');
    }
  }

  Future<void> _handleApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final fullName = [credential.givenName, credential.familyName]
          .where((e) => e != null && e.isNotEmpty)
          .join(' ');

      final result = await ApiService.socialLogin(
        provider: 'apple',
        providerUid: credential.userIdentifier ?? '',
        email: credential.email ?? '',
        fullName: fullName,
      );
      onResult(result.success, result.message);
    } catch (e) {
      onResult(false, 'Apple sign-in failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            icon: Icons.g_mobiledata_rounded,
            label: 'Google',
            onTap: _handleGoogle,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SocialButton(
            icon: Icons.apple,
            label: 'Apple',
            onTap: _handleApple,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<void> Function() onTap;
  const _SocialButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: AppColors.textPrimary),
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
    );
  }
}
