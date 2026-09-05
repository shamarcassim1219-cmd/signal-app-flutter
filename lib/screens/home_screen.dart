import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../config/app_colors.dart';
import '../models/instrument.dart';
import '../services/api_service.dart';
import 'signal_result_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';

class ChartCandle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  ChartCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory ChartCandle.fromJson(Map<String, dynamic> json) {
    return ChartCandle(
      time: DateTime.fromMillisecondsSinceEpoch(
          (double.parse(json['time'].toString()) * 1000).round()),
      open: double.parse(json['open'].toString()),
      high: double.parse(json['high'].toString()),
      low: double.parse(json['low'].toString()),
      close: double.parse(json['close'].toString()),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _baseUrl = 'https://finbassshamar.online';
  static const Duration _cooldownDuration = Duration(hours: 1);

  String _selectedMarket = 'crypto'; // 'forex' or 'crypto'
  List<Instrument> _instruments = [];
  bool _loading = true;
  Instrument? _selectedInstrument;
  bool _generating = false;
  Map<String, dynamic>? _planStatus;

  List<ChartCandle> _candles = [];
  bool _loadingChart = false;
  String _chartType = 'line'; // 'line' or 'candle'

  Map<int, DateTime> _cooldownUntil = {};
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _loadInstruments();
    _loadPlanStatus();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPlanStatus() async {
    final status = await ApiService.getPlanStatus();
    if (!mounted) return;
    setState(() => _planStatus = status);
  }

  Future<void> _loadInstruments() async {
    setState(() {
      _loading = true;
      _selectedInstrument = null;
      _candles = [];
    });
    final list = await ApiService.getInstruments(market: _selectedMarket);
    setState(() {
      _instruments = list;
      _loading = false;
    });
    _loadCooldownsFor(list);
  }

  Future<void> _loadCooldownsFor(List<Instrument> instruments) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, DateTime> loaded = {};
    for (final instrument in instruments) {
      final millis = prefs.getInt('cooldown_${instrument.id}');
      if (millis != null) {
        final until = DateTime.fromMillisecondsSinceEpoch(millis);
        if (until.isAfter(DateTime.now())) {
          loaded[instrument.id] = until;
        }
      }
    }
    if (!mounted) return;
    setState(() => _cooldownUntil = loaded);
  }

  Future<void> _startCooldown(int instrumentId) async {
    final until = DateTime.now().add(_cooldownDuration);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cooldown_$instrumentId', until.millisecondsSinceEpoch);
    if (!mounted) return;
    setState(() => _cooldownUntil[instrumentId] = until);
  }

  Duration? _remainingCooldown(int instrumentId) {
    final until = _cooldownUntil[instrumentId];
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  Future<void> _loadChart(int instrumentId) async {
    setState(() {
      _loadingChart = true;
      _candles = [];
    });
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/chart/$instrumentId'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List rawCandles = data['candles'] ?? [];
        final parsed = rawCandles.map((c) => ChartCandle.fromJson(c)).toList();
        if (!mounted) return;
        setState(() => _candles = parsed);
      }
    } catch (_) {
      // silently ignore - chart section shows "unavailable" state below
    } finally {
      if (mounted) setState(() => _loadingChart = false);
    }
  }

  Future<void> _handleGenerateSignal() async {
    if (_selectedInstrument == null) return;
    if (_remainingCooldown(_selectedInstrument!.id) != null) return;

    setState(() => _generating = true);
    final result = await ApiService.generateSignal(_selectedInstrument!.id);
    setState(() => _generating = false);

    if (!mounted) return;

    if (result['signal'] == null) {
      if (result['limitReached'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
          ),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
      return;
    }

    _startCooldown(_selectedInstrument!.id);
    _loadPlanStatus();

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
    final selectedRemaining = _selectedInstrument != null ? _remainingCooldown(_selectedInstrument!.id) : null;

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
          if (_selectedInstrument != null) _buildChartSection(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select the coin', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_planStatus != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_planStatus!['remaining']}/${_planStatus!['dailyLimit']} signals left today · ${(_planStatus!['plan'] as String)[0].toUpperCase()}${(_planStatus!['plan'] as String).substring(1)} plan',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
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
                          final remaining = _remainingCooldown(instrument.id);
                          final isLocked = remaining != null;

                          return GestureDetector(
                            onTap: isLocked
                                ? null
                                : () {
                                    setState(() => _selectedInstrument = instrument);
                                    _loadChart(instrument.id);
                                  },
                            child: Opacity(
                              opacity: isLocked ? 0.55 : 1.0,
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
                                    if (isLocked)
                                      Row(
                                        children: [
                                          const Icon(Icons.lock_clock, color: AppColors.textSecondary, size: 16),
                                          const SizedBox(width: 4),
                                          Text(_formatDuration(remaining), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      )
                                    else
                                      Icon(
                                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                  ],
                                ),
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
                onPressed: (_selectedInstrument == null || _generating || selectedRemaining != null) ? null : _handleGenerateSignal,
                child: _generating
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                    : Text(
                        selectedRemaining != null ? 'Available in ${_formatDuration(selectedRemaining)}' : 'Generate Signal',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 230,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedInstrument!.displayName,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              _chartTypeToggle('Line', 'line'),
              const SizedBox(width: 6),
              _chartTypeToggle('Candles', 'candle'),
            ],
          ),
          Expanded(
            child: _loadingChart
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                : _candles.isEmpty
                    ? const Center(
                        child: Text('Chart unavailable', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)))
                    : SfCartesianChart(
                        plotAreaBorderWidth: 0,
                        margin: EdgeInsets.zero,
                        primaryXAxis: const DateTimeAxis(isVisible: false, majorGridLines: MajorGridLines(width: 0)),
                        primaryYAxis: const NumericAxis(isVisible: false, majorGridLines: MajorGridLines(width: 0)),
                        series: _chartType == 'line'
                            ? <CartesianSeries>[
                                LineSeries<ChartCandle, DateTime>(
                                  dataSource: _candles,
                                  xValueMapper: (c, _) => c.time,
                                  yValueMapper: (c, _) => c.close,
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ]
                            : <CartesianSeries>[
                                CandleSeries<ChartCandle, DateTime>(
                                  dataSource: _candles,
                                  xValueMapper: (c, _) => c.time,
                                  lowValueMapper: (c, _) => c.low,
                                  highValueMapper: (c, _) => c.high,
                                  openValueMapper: (c, _) => c.open,
                                  closeValueMapper: (c, _) => c.close,
                                  bullColor: Colors.greenAccent,
                                  bearColor: Colors.redAccent,
                                ),
                              ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chartTypeToggle(String label, String value) {
    final isSelected = _chartType == value;
    return GestureDetector(
      onTap: () => setState(() => _chartType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
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
