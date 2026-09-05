import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/instrument.dart';
import '../services/api_service.dart';
import 'signal_result_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMarket = 'crypto'; // 'forex' or 'crypto'
  List<Instrument> _instruments = [];
  bool _loading = true;
  Instrument? _selectedInstrument;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadInstruments();
  }

  Future<void> _loadInstruments() async {
    setState(() {
      _loading = true;
      _selectedInstrument = null;
    });
    final list = await ApiService.getInstruments(market: _selectedMarket);
    setState(() {
      _instruments = list;
      _loading = false;
    });
  }

  Future<void> _handleGenerateSignal() async {
    if (_selectedInstrument == null) return;
    setState(() => _generating = true);
    final result = await ApiService.generateSignal(_selectedInstrument!.id);
    setState(() => _generating = false);

    if (!mounted) return;

    if (result['signal'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SignalResultScreen(
        signal: result['signal'],
        alreadyClaimedToday: result['alreadyClaimed'],
      ),
    ));
  }

  IconData _iconFor(String symbol) {
    switch (symbol) {
      case 'BTCUSDT':
        return Icons.currency_bitcoin;
      case 'ETHUSDT':
        return Icons.diamond_outlined;
      default:
        return Icons.show_chart;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Coin Market', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(child: _marketTab('Crypto', 'crypto')),
                  Expanded(child: _marketTab('Forex', 'forex')),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select the coin', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _instruments.isEmpty
                    ? const Center(
                        child: Text('No instruments available', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _instruments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final instrument = _instruments[index];
                          final isSelected = _selectedInstrument?.id == instrument.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedInstrument = instrument),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(_iconFor(instrument.symbol), color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(instrument.displayName,
                                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text(instrument.symbol,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  disabledBackgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: (_selectedInstrument == null || _generating) ? null : _handleGenerateSignal,
                child: _generating
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                    : const Text('Generate Signal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marketTab(String label, String value) {
    final isSelected = _selectedMarket == value;
    return GestureDetector(
      onTap: () {
        if (_selectedMarket != value) {
          setState(() => _selectedMarket = value);
          _loadInstruments();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.background : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
