import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const String _adminWhatsAppNumber = '94713051219'; // no + or leading 0
  static const String _adminTelegramUsername = 'My_signal_admin';

  String _currentPlan = 'free';
  bool _loading = true;

  final _plans = const [
    {
      'id': 'free',
      'title': 'Free',
      'price': 'LKR 0',
      'signals': '1 signal / day',
      'features': ['1 signal per day', 'Shows ads'],
    },
    {
      'id': 'subscribe',
      'title': 'Subscribe',
      'price': 'LKR 990/mo',
      'signals': '3 signals / day',
      'features': ['3 signals per day', 'No ads'],
    },
    {
      'id': 'premium',
      'title': 'Premium',
      'price': 'LKR 1990/mo',
      'signals': '5 signals / day',
      'features': ['5 signals per day', 'No ads', 'Priority support'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await ApiService.getPlanStatus();
    if (!mounted) return;
    setState(() {
      _currentPlan = status['plan'];
      _loading = false;
    });
  }

  Future<void> _launchWhatsApp(String planTitle) async {
    final message = Uri.encodeComponent('Hi, I want to upgrade my Signal App plan to $planTitle.');
    final uri = Uri.parse('https://wa.me/$_adminWhatsAppNumber?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
    }
  }

  Future<void> _launchTelegram(String planTitle) async {
    final uri = Uri.parse('https://t.me/$_adminTelegramUsername');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Telegram')));
    }
  }

  void _showContactAdminSheet(String planTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contact Admin to Upgrade',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Message admin to activate your $planTitle plan',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _contactIconButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      Navigator.pop(context);
                      _launchWhatsApp(planTitle);
                    },
                  ),
                  const SizedBox(width: 28),
                  _contactIconButton(
                    icon: Icons.send,
                    label: 'Telegram',
                    color: const Color(0xFF229ED9),
                    onTap: () {
                      Navigator.pop(context);
                      _launchTelegram(planTitle);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _contactIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Subscription', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  final isCurrent = plan['id'] == _currentPlan;
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isCurrent ? AppColors.primary : AppColors.border, width: isCurrent ? 2 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(plan['title'] as String,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.buy, borderRadius: BorderRadius.circular(8)),
                                child: const Text('Current', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(plan['price'] as String, style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ...List.generate((plan['features'] as List).length, (i) {
                          final feature = (plan['features'] as List)[i] as String;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.buy, size: 16),
                              const SizedBox(width: 8),
                              Text(feature, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ]),
                          );
                        }),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrent ? AppColors.border : AppColors.primary,
                              foregroundColor: isCurrent ? AppColors.textSecondary : AppColors.background,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isCurrent ? null : () => _showContactAdminSheet(plan['title'] as String),
                            child: Text(isCurrent ? 'Selected' : 'Contact Admin', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
