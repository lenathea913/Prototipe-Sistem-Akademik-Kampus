# KampusKu — Prototipe Sistem Akademik Kampus

Aplikasi sistem informasi akademik cross-platform untuk mahasiswa, dibangun dengan **Flutter** sebagai proyek akhir mata kuliah Mobile Programming (Tahap 1–5).

**Judul:** Prototipe Sistem Akademik Kampus Flutter dengan Arsitektur Offline-First dan Evaluasi Konsistensi Sinkronisasi

**Anggota B2:** Ryan Athallah Subekti (240605110150) · Muhammad Ainul Yakhin (240605110346) · Imam Abdul Hakim (240605110125)

## Fitur

| Fitur | Deskripsi |
|---|---|
| Login | Autentikasi dengan validasi form (NIM min. 8 karakter, sandi wajib). Mode prototipe: autentikasi lokal saat backend tidak terjangkau. |
| Beranda | Sapaan pengguna, ringkasan SKS (diambil / sisa kuota / jumlah matkul / batas), menu utama, jadwal hari ini, ringkasan kehadiran, pintasan presensi. |
| Jadwal | Daftar jadwal mingguan dengan filter per hari (chip) dan kondisi kosong. |
| KRS | Pengisian KRS dengan batas **24 SKS**, deteksi **bentrok jadwal**, cek duplikat, simpan/kosongkan (dengan konfirmasi). |
| Nilai | IPK, total SKS, dan rincian nilai per mata kuliah (Tugas 30% / UTS 30% / UAS 40%) yang dapat dibuka. |
| Presensi | Riwayat presensi dua pekan terakhir dengan warna+ikon per status (Hadir, Terlambat, Alpha, Izin, Sakit). |
| Profil | Data mahasiswa, menu Pengaturan/Bantuan/Tentang, logout dengan dialog konfirmasi. |

## Menjalankan

```bash
flutter pub get
flutter run          # perangkat/emulator terdeteksi
```

Kredensial mode prototipe (tanpa server): NIM `240605110150`, sandi `kampusku123`.

### Membangun APK

```bash
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

> Catatan build Windows: `android/gradle.properties` menyetel `kotlin.incremental=false` karena cache incremental Kotlin plugin `shared_preferences_android` gagal ditutup pada Windows dan menggagalkan `assembleRelease`.

## Arsitektur

Pemisahan lapisan mengikuti panduan struktur proyek Flutter — antarmuka, logika, data, dan layanan terpisah:

```
lib/
├── main.dart              # bootstrap, tema, orientasi, home = LoginScreen
├── screens/               # 7 layar (UI + state lokal via StatefulWidget)
│   ├── login_screen.dart      # form + validasi + routing ke dashboard
│   ├── dashboard_screen.dart  # bottom nav 5 tab + HomeTab (beranda)
│   ├── jadwal_screen.dart     # filter hari via FilterChip
│   ├── krs_screen.dart        # ringkasan SKS + daftar katalog + banner pesan
│   ├── nilai_screen.dart      # kartu IPK + ExpansionTile per matkul
│   ├── presensi_screen.dart   # riwayat presensi, warna status per kategori
│   └── profil_screen.dart     # data user + logout berkonfirmasi
├── models/                # MataKuliahModel, UserModel (+ Jadwal/Nilai/Presensi)
├── services/
│   ├── api_service.dart   # HTTP ke backend, fallback data lokal (timeout 4 dtk)
│   └── krs_service.dart   # aturan bisnis KRS: batas SKS, bentrok, duplikat
├── data/
│   ├── katalog_akademik.dart  # 12 mata kuliah Semester 5 + data mahasiswa
│   └── data_lokal.dart        # jadwal/nilai/presensi lokal, login lokal
├── utils/
│   ├── constants.dart     # baseUrl, endpoint, kunci penyimpanan, palet warna
│   └── waktu.dart         # menitDariJam, rentangWaktuBentrok (murni, teruji)
└── widgets/custom_widgets.dart  # MenuCard, InfoCard, ScheduleTile
```

### Keputusan desain penting

- **Offline-first (mode prototipe).** Setiap panggilan `ApiService` mencoba backend pada `AppConstants.baseUrl` dengan timeout 4 detik; bila gagal, memakai `data_lokal.dart` / `katalog_akademik.dart`. Aplikasi tetap penuh fungsi tanpa server — inilah dasar klaim arsitektur offline-first pada judul.
- **Aturan KRS terpusat di `KrsService`.** Validasi bertingkat: duplikat → tidak dikenal → batas 24 SKS → bentrok jadwal, sehingga pesan galat selalu yang paling relevan dan mudah diuji unit-test.
- **Bentrok jadwal memakai rentang setengah terbuka** (`waktu.dart`): kelas yang selesai tepat saat kelas lain mulai **tidak** dianggap bentrok.
- **Penyimpanan lokal via `shared_preferences`**: pilihan KRS dipertahankan saat logout (hingga sesi/kredensial yang dihapus).
- **State management `provider`** terdaftar di `pubspec.yaml` dan tersedia bila diperlukan; layar saat ini cukup dengan state lokal karena data per layar dimuat ulang saat dibuka.

## Pengujian

```bash
flutter analyze    # No issues found
flutter test       # 43/43 kasus lulus
```

| Berkas | Cakupan |
|---|---|
| `test/krs_service_test.dart` | Unit: parsing waktu, deteksi bentrok, aturan & pesan KRS, validitas katalog nyata. |
| `test/widget_test.dart` | Alur inti: login sukses/gagal/validasi, KRS (tambah, batalkan, batas SKS, simpan). |
| `test/tahap4_pengujian_test.dart` | Integrasi: navigasi 5 tab, filter jadwal, layar nilai, logout (batal/konfirmasi), pintasan presensi. |

Detail skenario, daftar bug, dan dokumentasi perbaikan: dokumen **Tahap 4** pada folder `../Project/`.

## Dokumentasi proyek

| Dokumen | Isi |
|---|---|
| `Project/Tahap 1 - …` | Judul, latar belakang, tujuan, pengguna, kebutuhan, fitur. |
| `Project/Tahap 2 - …` | Diagram alir, use case, navigasi, model data, wireframe. |
| `Project/Tahap 4 - …` | Skenario & tabel hasil pengujian, daftar kesalahan, perbaikan, hasil uji pengguna. |
| `Project/Tahap 5 - …` | Laporan proyek akhir dan bahan presentasi. |

## Ketergantungan utama

`provider`, `http`, `shared_preferences`, `google_fonts`, `flutter_svg`, `intl`, `pull_to_refresh`, `fl_chart`, `cupertino_icons` — seluruhnya umum dan dicantumkan di `pubspec.yaml` sesuai ketentuan transparansi pustaka eksternal.

## Lisensi

Proyek akhir Mobile Programming — penggunaan pustaka/sumber terbuka dicantumkan transparan pada bagian ini dan pada `pubspec.yaml`.
