import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/signal.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TradeSignal> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final list = await ApiService.getSignalHistory();
    if (!mounted) return;
    setState(() {
      _history = list;
      _loading = false;
    });
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/${dt.year} · $h:$min';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Signal History', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _history.isEmpty
                ? const Center(
                    child: Text('No signals generated yet', style: TextStyle(color: AppColors.textSecondary)))
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final signal = _history[index];
                        final isBuy = signal.direction.toUpperCase() == 'BUY';
                        final directionColor = isBuy ? Colors.greenAccent : Colors.redAccent;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${signal.name} (${signal.symbol})',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: directionColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      signal.direction.toUpperCase(),
                                      style: TextStyle(color: directionColor, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(signal.generatedAt),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _priceChip('Entry', signal.entryPrice),
                                  const SizedBox(width: 8),
                                  _priceChip('SL', signal.sl, color: Colors.redAccent),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _priceChip('TP1', signal.tp1, color: Colors.greenAccent),
                                  const SizedBox(width: 8),
                                  _priceChip('TP2', signal.tp2, color: Colors.greenAccent),
                                  const SizedBox(width: 8),
                                  _priceChip('TP3', signal.tp3, color: Colors.greenAccent),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Confidence: ${signal.confidence}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _priceChip(String label, double value, {Color color = AppColors.textPrimary}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value.toStringAsFixed(4), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
