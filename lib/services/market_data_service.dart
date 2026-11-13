import '../models/candle.dart';

abstract class MarketDataService {
  Future<List<Candle>> getCandles(String symbol, {int count = 80});
}

/// Demo-only source. It generates deterministic sample candles and does NOT
/// represent live or historical exchange prices.
class DemoMarketDataService implements MarketDataService {
  @override
  Future<List<Candle>> getCandles(String symbol, {int count = 80}) async {
    final now = DateTime.now();
    final seed = symbol.codeUnits.fold<int>(0, (a, b) => a + b);
    var price = 1000.0 + (seed % 9000);
    final candles = <Candle>[];

    for (var i = count - 1; i >= 0; i--) {
      final step = i + seed;
      final drift = ((step * 17) % 11 - 5) * 0.0018;
      final wave = (step % 7 - 3) * 0.0012;
      final open = price;
      price = (price * (1 + drift + wave)).clamp(100, 50000).toDouble();
      final close = price;
      final spread = (close * (0.001 + (step % 4) * 0.0005));
      final high = (open > close ? open : close) + spread;
      final low = (open < close ? open : close) - spread;
      final volume = 100000 + ((step * 7919) % 180000);
      candles.add(Candle(
        time: now.subtract(Duration(minutes: 5 * i)),
        open: open, high: high, low: low, close: close, volume: volume.toDouble(),
      ));
    }
    return candles;
  }
}
