class TradeSignal {
  final String symbol;
  final String name;
  final String direction; // BUY or SELL
  final double entryPrice;
  final double tp1;
  final double tp2;
  final double tp3;
  final double sl;
  final String confidence;
  final String generatedAt;

  TradeSignal({
    required this.symbol,
    required this.name,
    required this.direction,
    required this.entryPrice,
    required this.tp1,
    required this.tp2,
    required this.tp3,
    required this.sl,
    required this.confidence,
    required this.generatedAt,
  });

  factory TradeSignal.fromJson(Map<String, dynamic> json) {
    return TradeSignal(
      symbol: json['symbol'],
      name: json['name'],
      direction: json['direction'],
      entryPrice: double.parse(json['entry_price'].toString()),
      tp1: double.parse(json['tp1'].toString()),
      tp2: double.parse(json['tp2'].toString()),
      tp3: double.parse(json['tp3'].toString()),
      sl: double.parse(json['sl'].toString()),
      confidence: json['confidence'],
      generatedAt: json['generated_at'],
    );
  }
}
