// test/tahap4_pengujian_test.dart
//
// Pengujian integrasi Tahap 4: memastikan seluruh fitur yang disatukan
// tetap terhubung setelah digabung - navigasi antar tab, filter jadwal,
// layar nilai, profil dengan konfirmasi logout, dan pintasan presensi
// dari beranda (perbaikan layar presensi yang tidak terjangkau).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kampus_ku/data/data_lokal.dart';
import 'package:kampus_ku/main.dart';
import 'package:kampus_ku/screens/presensi_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _bukaAplikasi(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const KampusKuApp());
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), kNimDemo);
  await tester.enterText(find.byType(TextFormField).at(1), kSandiDemo);
  await tester.tap(find.text('MASUK'));
  await tester.pumpAndSettle();
}

/// Ketuk sebuah label pada bottom navigation bar.
Future<void> _pindahTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Gulir elemen ke dalam viewport.
Future<void> _tampilkan(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Tahap 4 - navigasi antar tab', () {
    testWidgets('setiap tab bottom navigation menampilkan layarnya',
        (tester) async {
      await _bukaAplikasi(tester);
      await _login(tester);

      expect(find.text('Ringkasan Akademik'), findsOneWidget);

      await _pindahTab(tester, 'Jadwal');
      expect(find.text('Jadwal Kuliah'), findsOneWidget);
      expect(find.text('Filter') /* tidak ada */, findsNothing);

      await _pindahTab(tester, 'KRS');
      expect(find.text('Pengisian KRS'), findsOneWidget);

      await _pindahTab(tester, 'Nilai');
      expect(find.text('Daftar Nilai'), findsOneWidget);
      expect(find.text('Indeks Prestasi Kumulatif'), findsOneWidget);

      await _pindahTab(tester, 'Profil');
      expect(find.text('Profil Saya'), findsOneWidget);

      await _pindahTab(tester, 'Beranda');
      expect(find.text('Ringkasan Akademik'), findsOneWidget);
    });
  });

  group('Tahap 4 - filter jadwal per hari', () {
    testWidgets('memilih hari hanya menampilkan kelas hari itu',
        (tester) async {
      await _bukaAplikasi(tester);
      await _login(tester);
      await _pindahTab(tester, 'Jadwal');

      // Semua kelas tampil pada filter "Semua".
      expect(find.text('Pemrograman Mobile'), findsOneWidget); // Senin
      expect(find.text('Jaringan Komputer'), findsOneWidget); // Selasa

      await tester.tap(find.widgetWithText(FilterChip, 'Selasa'));
      await tester.pumpAndSettle();

      // Hanya kelas Selasa yang tersisa.
      expect(find.text('Jaringan Komputer'), findsOneWidget);
      expect(find.text('Pemrograman Mobile'), findsNothing);
      expect(find.text('Pemrograman Web Lanjut'), findsOneWidget);
      expect(find.text('Keamanan Informasi'), findsOneWidget);

      // Hari tanpa kelas menampilkan kondisi kosong.
      await tester.tap(find.widgetWithText(FilterChip, 'Sabtu'));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada jadwal'), findsOneWidget);
    });
  });

  group('Tahap 4 - layar nilai', () {
    testWidgets('nilai menampilkan IPK, total SKS, dan detail per matkul',
        (tester) async {
      await _bukaAplikasi(tester);
      await _login(tester);
      await _pindahTab(tester, 'Nilai');

      expect(find.text('Indeks Prestasi Kumulatif'), findsOneWidget);
      expect(find.text('Total SKS: 33'), findsOneWidget);
      expect(find.text('Detail Nilai'), findsOneWidget);
      expect(find.text('Pemrograman Mobile'), findsOneWidget);

      // Buka detail satu mata kuliah.
      await tester.tap(find.text('Pemrograman Mobile'));
      await tester.pumpAndSettle();
      expect(find.text('Tugas'), findsWidgets);
      expect(find.text('Nilai Akhir'), findsOneWidget);
    });
  });

  group('Tahap 4 - profil dan logout', () {
    testWidgets('logout menampilkan konfirmasi dan batal tetap di profil',
        (tester) async {
      await _bukaAplikasi(tester);
      await _login(tester);
      await _pindahTab(tester, 'Profil');

      expect(find.text('NIM: $kNimDemo'), findsOneWidget);
      expect(find.text('Program Studi'), findsOneWidget);

      // Tombol logout berada di paling bawah halaman profil.
      await _tampilkan(tester, find.text('KELUAR'));
      await tester.tap(find.text('KELUAR'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Logout'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Logout'), findsNothing);
      expect(find.text('Profil Saya'), findsOneWidget);
    });

    testWidgets('logout dikonfirmasi mengembalikan ke layar login',
        (tester) async {
      await _bukaAplikasi(tester);
      await _login(tester);
      await _pindahTab(tester, 'Profil');

      await _tampilkan(tester, find.text('KELUAR'));
      await tester.tap(find.text('KELUAR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(find.text('MASUK'), findsOneWidget);
      expect(find.text('Mode Prototipe (tanpa server)'), findsOneWidget);
    });
  });

  group('Tahap 4 - pintasan presensi dari beranda', () {
    testWidgets('beranda membuka layar Riwayat Presensi', (tester) async {
      await _bukaAplikasi(tester);
      await _login(tester);

      // Pintasan berada di paling bawah beranda.
      await _tampilkan(tester, find.text('Riwayat Presensi'));
      expect(find.text('Riwayat Presensi'), findsOneWidget);
      expect(find.textContaining('Kehadiran'), findsWidgets);

      await tester.tap(find.text('Riwayat Presensi'));
      await tester.pumpAndSettle();

      expect(find.byType(PresensiScreen), findsOneWidget);
      // Data presensi lokal selalu terisi untuk dua pekan terakhir.
      expect(find.text(presensiLokal().first['mata_kuliah'] as String),
          findsWidgets);
    });
  });
}
