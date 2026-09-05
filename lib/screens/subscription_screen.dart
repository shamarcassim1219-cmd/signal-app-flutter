import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _currentPlan = 'free';
  bool _loading = true;
  bool _changing = false;

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

  Future<void> _selectPlan(String planId) async {
    if (planId == _currentPlan) return;
    setState(() => _changing = true);
    final result = await ApiService.changePlan(planId);
    setState(() => _changing = false);
    if (!mounted) return;

    if (result.success) {
      setState(() => _currentPlan = planId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan updated to ${planId[0].toUpperCase()}${planId.substring(1)}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    }
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
                            onPressed: (isCurrent || _changing) ? null : () => _selectPlan(plan['id'] as String),
                            child: Text(isCurrent ? 'Selected' : 'Select', style: const TextStyle(fontWeight: FontWeight.w600)),
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
