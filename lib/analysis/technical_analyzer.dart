import '../models/candle.dart';

enum Signal { buy, wait, avoid }

class AnalysisResult {
  final Signal signal;
  final int score;
  final double? rsi;
  final double? ema9;
  final double? ema21;
  final double? macd;
  final double? macdSignal;
  final double volumeRatio;
  final bool bullishCandle;
  final List<String> reasons;

  const AnalysisResult({
    required this.signal,
    required this.score,
    required this.rsi,
    required this.ema9,
    required this.ema21,
    required this.macd,
    required this.macdSignal,
    required this.volumeRatio,
    required this.bullishCandle,
    required this.reasons,
  });
}

class TechnicalAnalyzer {
  AnalysisResult analyze(List<Candle> candles) {
    if (candles.length < 35) {
      return const AnalysisResult(
        signal: Signal.wait, score: 0, rsi: null, ema9: null, ema21: null,
        macd: null, macdSignal: null, volumeRatio: 0, bullishCandle: false,
        reasons: ['Data belum cukup. Dibutuhkan minimal 35 candle.'],
      );
    }

    final closes = candles.map((c) => c.close).toList();
    final volumes = candles.map((c) => c.volume).toList();

    final rsi = _rsi(closes, 14);
    final ema9 = _ema(closes, 9);
    final ema21 = _ema(closes, 21);

    final macdLine = _macdSeries(closes);
    final macd = macdLine.isNotEmpty ? macdLine.last : null;
    final macdSignal = macdLine.isNotEmpty ? _ema(macdLine, 9) : null;

    final avgVolume = volumes.sublist(volumes.length - 21, volumes.length - 1)
        .reduce((a, b) => a + b) / 20;
    final volumeRatio = avgVolume == 0 ? 0 : volumes.last / avgVolume;

    final last = candles.last;
    final bullishCandle = last.close > last.open;
    final previous = candles[candles.length - 2];
    final bullishEngulfing = last.close > last.open &&
        previous.close < previous.open &&
        last.open <= previous.close &&
        last.close >= previous.open;

    var score = 0;
    final reasons = <String>[];

    if (rsi != null && rsi >= 45 && rsi <= 65) {
      score++;
      reasons.add('RSI berada di zona momentum sehat (${rsi.toStringAsFixed(1)}).');
    } else if (rsi != null && rsi > 70) {
      reasons.add('RSI ${rsi.toStringAsFixed(1)}: kondisi berpotensi jenuh beli.');
    } else if (rsi != null) {
      reasons.add('RSI ${rsi.toStringAsFixed(1)} belum memberi konfirmasi momentum.');
    }

    if (ema9 != null && ema21 != null && ema9 > ema21) {
      score++;
      reasons.add('EMA 9 berada di atas EMA 21: tren jangka pendek positif.');
    } else {
      reasons.add('EMA 9 belum berada di atas EMA 21.');
    }

    if (macd != null && macdSignal != null && macd > macdSignal) {
      score++;
      reasons.add('MACD berada di atas garis sinyal.');
    } else {
      reasons.add('MACD belum mengonfirmasi momentum bullish.');
    }

    if (volumeRatio >= 1.2) {
      score++;
      reasons.add('Volume ${volumeRatio.toStringAsFixed(2)}x rata-rata 20 candle.');
    } else {
      reasons.add('Volume belum meningkat signifikan (${volumeRatio.toStringAsFixed(2)}x).');
    }

    if (bullishCandle || bullishEngulfing) {
      score++;
      reasons.add(bullishEngulfing
          ? 'Terbentuk pola bullish engulfing.'
          : 'Candle terakhir ditutup bullish.');
    } else {
      reasons.add('Candle terakhir belum menunjukkan penutupan bullish.');
    }

    final overbought = rsi != null && rsi >= 70;
    final bearishTrend = ema9 != null && ema21 != null && ema9 < ema21 &&
        macd != null && macdSignal != null && macd < macdSignal;

    final Signal signal;
    if (bearishTrend || (overbought && score < 4)) {
      signal = Signal.avoid;
    } else if (score >= 4 && !overbought) {
      signal = Signal.buy;
    } else {
      signal = Signal.wait;
    }

    return AnalysisResult(
      signal: signal, score: score, rsi: rsi, ema9: ema9, ema21: ema21,
macd: macd, macdSignal: macdSignal, volumeRatio: volumeRatio.toDouble(),      macd: macd, macdSignal: macdSignal, volumeRatio: volumeRatio,
      bullishCandle: bullishCandle, reasons: reasons,
    );
  }

  double? _rsi(List<double> values, int period) {
    if (values.length <= period) return null;
    var gains = 0.0;
    var losses = 0.0;
    for (var i = values.length - period; i < values.length; i++) {
      final change = values[i] - values[i - 1];
      if (change > 0) gains += change;
      if (change < 0) losses -= change;
    }
    final avgGain = gains / period;
    final avgLoss = losses / period;
    if (avgLoss == 0) return 100;
    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  double _ema(List<double> values, int period, {bool fullSeries = false}) {
    if (values.isEmpty) return 0;
    final k = 2 / (period + 1);
    final start = period < values.length ? period : values.length;
    var ema = values.take(start).reduce((a, b) => a + b) / start;
    for (var i = start; i < values.length; i++) {
      ema = values[i] * k + ema * (1 - k);
    }
    return ema;
  }

  List<double> _macdSeries(List<double> closes) {
    final result = <double>[];
    for (var i = 25; i < closes.length; i++) {
      final slice = closes.sublist(0, i + 1);
      result.add(_ema(slice, 12) - _ema(slice, 26));
    }
    return result;
  }
}
