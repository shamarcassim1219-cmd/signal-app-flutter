import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';

class AddMobileScreen extends StatefulWidget {
  const AddMobileScreen({super.key});
  @override
  State<AddMobileScreen> createState() => _AddMobileScreenState();
}

class _AddMobileScreenState extends State<AddMobileScreen> {
  final _mobileController = TextEditingController();
  bool _loading = false;

  Future<void> _handleSave() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your mobile number')));
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.updateMobile(mobile);
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
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: const Text('Mobile Number', style: TextStyle(color: AppColors.textPrimary))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a valid Sri Lankan mobile number',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Mobile Number (e.g. 0771234567)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.phone_android_outlined, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: _loading ? null : _handleSave,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Mobile Number'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
