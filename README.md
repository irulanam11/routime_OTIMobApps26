# Routime

Aplikasi pelacak kebiasaan harian berbasis Flutter. Tambahkan kebiasaan, centang setiap hari,
pantau *streak*, dan gunakan timer fokus (Countdown, Stopwatch, Pomodoro) untuk kebiasaan tertentu.

Penugasan Mobile Apps OmahTI 2026.

## Fitur

- Daftar kebiasaan harian dengan progress ring dan streak
- Tambah, edit, dan hapus kebiasaan (nama, deskripsi, warna, opsi timer)
- Detail kebiasaan: streak saat ini, streak terpanjang, kalender bulanan
- Timer per kebiasaan: Countdown, Stopwatch, Pomodoro, dengan notifikasi lokal
- Statistik: ringkasan bulan, kalender konsistensi, grafik mingguan, peringkat kebiasaan
- Penyimpanan lokal (data tetap ada setelah aplikasi ditutup)
- Layar responsif dan adaptif: navigasi bawah di HP, navigation rail dan dua panel di layar lebar
- Tema kustom (warna hijau, font Poppins) dan animasi (splash, progress ring, pemilih mode)

## Teknologi

| Kebutuhan | Yang dipakai |
|---|---|
| Framework | Flutter |
| State management | Provider (`ChangeNotifier`) |
| Penyimpanan lokal | `shared_preferences` |
| Notifikasi | `flutter_local_notifications`, `timezone`, `flutter_timezone` |

## Struktur proyek

```
lib/
├── main.dart            # titik masuk, MultiProvider, observer siklus hidup
├── models/              # Habit
├── providers/           # HabitProvider, TimerProvider (state)
├── services/            # StorageService, NotificationService
├── screens/             # Splash, MainShell, Home, Detail, Form, Statistik
├── widgets/             # ProgressRing, TimerWidget, dialog
├── utils/               # date_utils, stats_utils (logika murni), responsive
└── theme/               # AppColors, AppTheme
test/                    # tes model, provider, util, dan widget
```

Alur data: **screen/widget → provider → service → penyimpanan lokal**.
Logika perhitungan statistik dipisahkan di `utils/stats_utils.dart` agar mudah diuji.

## Menjalankan

```bash
flutter pub get
flutter run
```

## Menguji

```bash
flutter test
```

## Build APK

```bash
flutter build apk --release
```

Hasil: `build/app/outputs/flutter-apk/app-release.apk`

## Dokumentasi

- Slicing UI: `docs/SLICING_UI.md`
