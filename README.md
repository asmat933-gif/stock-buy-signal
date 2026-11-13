# Stock Buy Signal — Android MVP

Aplikasi Flutter untuk eksperimen analisis teknikal saham BEI dengan strategi Day Trading.

## Status saat ini
- Dashboard Android Flutter.
- Watchlist awal: BBCA, BBRI, BMRI, TLKM, ANTM.
- Tambah kode saham BEI 4 huruf.
- Mesin analisis RSI(14), EMA(9/21), MACD(12/26/9), rasio volume, dan candle bullish.
- Klasifikasi BUY / WAIT / AVOID.
- **Data masih simulasi/dummy. Tidak terhubung ke BEI dan jangan digunakan untuk transaksi nyata.**

## Menjalankan di Android
1. Install Flutter SDK dan Android Studio.
2. Ekstrak ZIP ini.
3. Buka terminal di folder `stock_buy_signal`.
4. Jalankan:
   ```bash
   flutter create . --platforms=android
   flutter pub get
   flutter run
   ```
5. Untuk membuat APK debug:
   ```bash
   flutter build apk --debug
   ```
   APK biasanya berada di `build/app/outputs/flutter-apk/app-debug.apk`.

## Struktur
- `lib/main.dart`: dashboard dan antarmuka.
- `lib/models/candle.dart`: model OHLCV.
- `lib/analysis/technical_analyzer.dart`: perhitungan indikator dan aturan sinyal.
- `lib/services/market_data_service.dart`: abstraksi sumber data; saat ini DemoMarketDataService.

## Tahap integrasi data aktual
Ganti `DemoMarketDataService` dengan implementasi `MarketDataService` yang mengambil candle OHLCV intraday dari penyedia data yang:
- secara eksplisit mendukung ticker BEI (misalnya BBCA.JK),
- menyediakan interval 5 menit dan 15 menit,
- memiliki ketentuan lisensi yang mengizinkan penggunaan di aplikasi,
- menjelaskan keterlambatan data, batas request, dan penggunaan komersial.

Jangan menaruh API secret di aplikasi Android. Gunakan backend/server perantara untuk menyimpan secret dan meneruskan data ke aplikasi.

## Catatan metodologi
Sinyal hanya alat bantu probabilistik. Backtest, biaya transaksi, slippage, likuiditas, spread, suspensi saham, dan validasi out-of-sample harus ditambahkan sebelum penggunaan nyata. Gunakan candle yang sudah selesai agar sinyal tidak berubah-ubah di tengah candle.
