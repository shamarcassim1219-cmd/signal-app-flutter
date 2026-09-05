import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/signal.dart';

class SignalResultScreen extends StatelessWidget {
  final TradeSignal signal;
  final bool alreadyClaimedToday;
  const SignalResultScreen({super.key, required this.signal, this.alreadyClaimedToday = false});

  @override
  Widget build(BuildContext context) {
    final isBuy = signal.direction == 'BUY';
    final directionColor = isBuy ? AppColors.buy : AppColors.sell;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Signal', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alreadyClaimedToday)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "This is today's signal. Come back tomorrow for a new one.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(signal.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: directionColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(isBuy ? Icons.trending_up : Icons.trending_down, color: directionColor, size: 18),
                        const SizedBox(width: 6),
                        Text(signal.direction, style: TextStyle(color: directionColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(signal.symbol, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              _priceCard('Entry Price', signal.entryPrice, AppColors.textPrimary),
              const SizedBox(height: 12),
              _priceCard('Stop Loss (SL)', signal.sl, AppColors.sell),
              const SizedBox(height: 20),
              const Text('Take Profit Targets', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _tpCard('TP1', signal.tp1, recommended: true),
              const SizedBox(height: 10),
              _tpCard('TP2', signal.tp2),
              const SizedBox(height: 10),
              _tpCard('TP3', signal.tp3),
              const SizedBox(height: 24),
              _confidenceMeter(signal.confidence),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'This signal is based on technical analysis (MACD, RSI, ATR) and is for informational purposes only. Trading involves risk - always manage your position size.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceCard(String label, double value, Color valueColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value.toStringAsFixed(5), style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tpCard(String label, double value, {bool recommended = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommended ? AppColors.buy.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: recommended ? AppColors.buy : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            if (recommended) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.buy, borderRadius: BorderRadius.circular(6)),
                child: const Text('Recommended', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ]),
          Text(value.toStringAsFixed(5), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _confidenceMeter(String confidence) {
    int level;
    String label;
    Color color;

    switch (confidence) {
      case 'HIGH':
        level = 3;
        label = 'Strong Setup';
        color = AppColors.buy;
        break;
      case 'MEDIUM':
        level = 2;
        label = 'Good Setup';
        color = Colors.amber;
        break;
      default:
        level = 1;
        label = 'Fair Setup';
        color = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Row(
            children: List.generate(3, (i) {
              final filled = i < level;
              return Container(
                margin: const EdgeInsets.only(right: 4),
                width: 26,
                height: 10,
                decoration: BoxDecoration(
                  color: filled ? color : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
