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
  int? _generatingId;

  @override
  void initState() {
    super.initState();
    _loadInstruments();
  }

  Future<void> _loadInstruments() async {
    setState(() => _loading = true);
    final list = await ApiService.getInstruments(market: _selectedMarket);
    setState(() {
      _instruments = list;
      _loading = false;
    });
  }

  Future<void> _handleGenerateSignal(Instrument instrument) async {
    setState(() => _generatingId = instrument.id);
    final result = await ApiService.generateSignal(instrument.id);
    setState(() => _generatingId = null);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Signals', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
            child: Row(
              children: [
                Expanded(child: _marketTab('Crypto', 'crypto')),
                const SizedBox(width: 12),
                Expanded(child: _marketTab('Forex', 'forex')),
              ],
            ),
          ),
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
                          final isGenerating = _generatingId == instrument.id;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
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
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.background,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: isGenerating ? null : () => _handleGenerateSignal(instrument),
                                  child: isGenerating
                                      ? const SizedBox(
                                          height: 16, width: 16,
                                          child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                                      : const Text('Generate'),
                                ),
                              ],
                            ),
                          );
                        },
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
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
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
