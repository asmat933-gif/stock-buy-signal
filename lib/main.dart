import 'package:flutter/material.dart';
import 'analysis/technical_analyzer.dart';
import 'models/candle.dart';
import 'services/market_data_service.dart';

void main() => runApp(const StockBuySignalApp());

class StockBuySignalApp extends StatelessWidget {
  const StockBuySignalApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B1220);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Buy Signal',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16A36A), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _service = DemoMarketDataService();
  final _analyzer = TechnicalAnalyzer();
  final _controller = TextEditingController();
  final List<String> _symbols = ['BBCA', 'BBRI', 'BMRI', 'TLKM', 'ANTM'];
  final Map<String, List<Candle>> _data = {};
  final Map<String, AnalysisResult> _results = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      for (final symbol in _symbols) {
        final candles = await _service.getCandles('$symbol.JK');
        _data[symbol] = candles;
        _results[symbol] = _analyzer.analyze(candles);
      }
    } catch (e) {
      _error = 'Gagal memuat data: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _addSymbol() {
    final value = _controller.text.trim().toUpperCase().replaceAll('.JK', '');
    if (value.isEmpty || !RegExp(r'^[A-Z]{4}$').hasMatch(value)) {
      setState(() => _error = 'Masukkan kode saham BEI 4 huruf, contoh: ASII.');
      return;
    }
    if (!_symbols.contains(value)) {
      setState(() => _symbols.add(value));
      _controller.clear();
      _refreshAll();
    } else {
      _controller.clear();
    }
  }

  String _rupiah(double value) =>
      'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  Color _signalColor(Signal signal) {
    switch (signal) {
      case Signal.buy: return const Color(0xFF27C281);
      case Signal.wait: return const Color(0xFFF2B84B);
      case Signal.avoid: return const Color(0xFFEF6262);
    }
  }

  String _signalText(Signal signal) {
    switch (signal) {
      case Signal.buy: return 'BUY';
      case Signal.wait: return 'WAIT';
      case Signal.avoid: return 'AVOID';
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyCount = _results.values.where((r) => r.signal == Signal.buy).length;
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('STOCK BUY SIGNAL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
          Text('BEI • DAY TRADING', style: TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
        actions: [
          IconButton(onPressed: _loading ? null : _refreshAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _marketBanner(buyCount),
            const SizedBox(height: 16),
            _sectionTitle('WATCHLIST SAHAM', 'Analisis timeframe demo 5 menit'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
                decoration: const InputDecoration(
                  counterText: '', hintText: 'Kode saham, contoh ASII',
                  filled: true, border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addSymbol(),
              )),
              const SizedBox(width: 8),
              FilledButton(onPressed: _addSymbol, child: const Icon(Icons.add)),
            ]),
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
            ),
            const SizedBox(height: 8),
            if (_loading && _results.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
            ..._symbols.map(_stockCard),
            const SizedBox(height: 18),
            _sectionTitle('ATURAN SINYAL', 'Konfirmasi teknikal'),
            Card(color: const Color(0xFF151F30), child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                _RuleRow(icon: Icons.trending_up, text: 'RSI 14: momentum sehat 45–65'),
                _RuleRow(icon: Icons.show_chart, text: 'EMA 9 di atas EMA 21'),
                _RuleRow(icon: Icons.multiline_chart, text: 'MACD di atas garis sinyal'),
                _RuleRow(icon: Icons.bar_chart, text: 'Volume minimal 1,2x rata-rata'),
                _RuleRow(icon: Icons.candlestick_chart, text: 'Candle terakhir bullish'),
                SizedBox(height: 8),
                Text('BUY memerlukan minimal 4 dari 5 konfirmasi dan tidak dalam kondisi jenuh beli.',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            )),
            const SizedBox(height: 16),
            const Text('PENTING: Versi ini menggunakan data simulasi. Sinyal bukan rekomendasi investasi dan tidak boleh dipakai untuk transaksi nyata.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _marketBanner(int buyCount) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF123C35), Color(0xFF17283A)]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PELUANG TERDETEKSI', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text('$buyCount saham', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const Text('memenuhi kriteria BUY saat ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
      ])),
      const Icon(Icons.radar, size: 48, color: Color(0xFF48D6A0)),
    ]),
  );

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: .5)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ],
  );

  Widget _stockCard(String symbol) {
    final candles = _data[symbol];
    final result = _results[symbol];
    if (candles == null || result == null) {
      return Card(child: ListTile(title: Text(symbol), subtitle: const Text('Memuat analisis...')));
    }
    final color = _signalColor(result.signal);
    final lastPrice = candles.last.close;
    return Card(
      color: const Color(0xFF151F30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              Text(_rupiah(lastPrice), style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(20)),
              child: Text(_signalText(result.signal), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
          ]),
          const Divider(height: 22, color: Colors.white12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _metric('SKOR', '${result.score}/5'),
            _metric('RSI', result.rsi?.toStringAsFixed(1) ?? '-'),
            _metric('VOLUME', '${result.volumeRatio.toStringAsFixed(2)}x'),
            _metric('TIMEFRAME', '5m'),
          ]),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: Text(
            result.reasons.take(2).join(' • '),
            style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
          )),
        ]),
      ),
    );
  }

  Widget _metric(String label, String value) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ]);
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RuleRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 17, color: const Color(0xFF48D6A0)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
    ]),
  );
}
