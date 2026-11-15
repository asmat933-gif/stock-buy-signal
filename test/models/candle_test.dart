
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_buy_signal/models/candle.dart';

void main() {
  test('Candle menyimpan data OHLCV dengan benar', () {
    final time = DateTime.utc(2026, 11, 15, 9, 0);

    final candle = Candle(
      time: time,
      open: 1000,
      high: 1100,
      low: 950,
      close: 1050,
      volume: 20000,
    );

    expect(candle.time, time);
    expect(candle.open, 1000);
    expect(candle.high, 1100);
    expect(candle.low, 950);
    expect(candle.close, 1050);
    expect(candle.volume, 20000);
  });
}
