class Instrument {
  final int id;
  final String symbol;
  final String displayName;
  final String marketType; // 'forex' or 'crypto'

  Instrument({
    required this.id,
    required this.symbol,
    required this.displayName,
    required this.marketType,
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    return Instrument(
      id: int.parse(json['id'].toString()),
      symbol: json['symbol'],
      displayName: json['display_name'],
      marketType: json['market_type'],
    );
  }
}
