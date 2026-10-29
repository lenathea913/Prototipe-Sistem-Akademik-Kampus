// lib/services/krs_service.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/katalog_akademik.dart';
import '../models/matakuliah_model.dart';

/// Hasil pengecekan ketika sebuah mata kuliah hendak ditambahkan ke KRS.
enum StatusTambah {
  /// Mata kuliah layak ditambahkan.
  oke,

  /// Total SKS akan melebihi batas yang diizinkan.
  melebihiBatasSks,

  /// Waktu mata kuliah ini tumpang tindih dengan mata kuliah yang sudah dipilih.
  bentrokJadwal,

  /// Mata kuliah sudah ada di dalam KRS.
  sudahDipilih,

  /// Kode mata kuliah tidak ditemukan di katalog.
  tidakDikenal,
}

/// Alasan sebuah penambahan ditolak, lengkap dengan pesan untuk pengguna.
class HasilValidasiKrs {
  final StatusTambah status;

  /// Mata kuliah yang menyebabkan bentrok; hanya terisi bila [status]
  /// bernilai [StatusTambah.bentrokJadwal].
  final MataKuliahModel? penyebabBentrok;

  const HasilValidasiKrs(this.status, {this.penyebabBentrok});

  bool get diperbolehkan => status == StatusTambah.oke;
}

/// Aturan main KRS yang menjadi inti Tahap 3.
///
/// Seluruh metode bersifat statis dan tanpa efek samping supaya aturan bisa
/// diuji langsung oleh unit test maupun dipanggil dari UI.
class KrsService {
  /// Batas maksimum SKS yang boleh diambil satu semester.
  static const int batasSks = 24;

  /// Kunci penyimpanan pilihan KRS di penyimpanan lokal.
  static const String kunciSimpan = 'krs_terpilih_v1';

  /// Jumlah total SKS dari daftar mata kuliah terpilih.
  static int totalSks(List<MataKuliahModel> dipilih) {
    return dipilih.fold(0, (jumlah, matkul) => jumlah + matkul.sks);
  }

  /// Cari mata kuliah pada [dipilih] yang waktunya tumpang tindih dengan
  /// [kandidat]. Mengembalikan null bila tidak ada bentrok.
  static MataKuliahModel? cariBentrok(
    MataKuliahModel kandidat,
    List<MataKuliahModel> dipilih,
  ) {
    for (final matkul in dipilih) {
      if (matkul.kode == kandidat.kode) continue;
      if (matkul.bentrokDengan(kandidat)) return matkul;
    }
    return null;
  }

  /// Validasi utama: apakah [kode] boleh ditambahkan ke [dipilih]?
  ///
  /// Urutan pemeriksaan: keberadaan di katalog, duplikasi, batas SKS, lalu
  /// bentrok jadwal. Batas SKS dicek lebih dulu karena pesannya lebih jelas
  /// bagi mahasiswa daripada pesan bentrok yang sekaligus penuh.
  static HasilValidasiKrs validasiTambah({
    required String kode,
    required List<MataKuliahModel> dipilih,
    List<MataKuliahModel>? katalog,
  }) {
    final daftarKatalog = katalog ?? katalogSemester5;

    final sudahDipilih = dipilih.any((m) => m.kode == kode);
    if (sudahDipilih) {
      return const HasilValidasiKrs(StatusTambah.sudahDipilih);
    }

    MataKuliahModel? kandidat;
    for (final m in daftarKatalog) {
      if (m.kode == kode) {
        kandidat = m;
        break;
      }
    }
    if (kandidat == null) {
      return const HasilValidasiKrs(StatusTambah.tidakDikenal);
    }

    final totalSekarang = totalSks(dipilih);
    if (totalSekarang + kandidat.sks > batasSks) {
      return const HasilValidasiKrs(StatusTambah.melebihiBatasSks);
    }

    final bentrok = cariBentrok(kandidat, dipilih);
    if (bentrok != null) {
      return HasilValidasiKrs(StatusTambah.bentrokJadwal, penyebabBentrok: bentrok);
    }

    return const HasilValidasiKrs(StatusTambah.oke);
  }

  /// Susun pesan yang layak ditampilkan ke pengguna untuk sebuah [hasil].
  ///
  /// [dipilih] dipakai untuk menghitung sisa kuota SKS yang tersisa.
  static String pesanDari(
    HasilValidasiKrs hasil, {
    MataKuliahModel? kandidat,
    List<MataKuliahModel> dipilih = const [],
  }) {
    final terpakai = totalSks(dipilih);
    final sisaKuota = batasSks - terpakai;

    switch (hasil.status) {
      case StatusTambah.oke:
        return 'Mata kuliah ditambahkan ke KRS.';
      case StatusTambah.melebihiBatasSks:
        final butuh = kandidat?.sks ?? 0;
        return 'Melebihi batas $batasSks SKS: butuh $butuh SKS, '
            'tersisa hanya $sisaKuota SKS.';
      case StatusTambah.bentrokJadwal:
        final b = hasil.penyebabBentrok;
        return 'Bentrok jadwal dengan ${b?.nama ?? 'mata kuliah lain'} '
            'pada ${b?.hari ?? ''} ${b?.rentangJam ?? ''}.';
      case StatusTambah.sudahDipilih:
        return 'Mata kuliah sudah ada di dalam KRS.';
      case StatusTambah.tidakDikenal:
        return 'Mata kuliah tidak ditemukan di katalog.';
    }
  }

  /// Ambil KRS tersimpan dari penyimpanan lokal.
  ///
  /// Mengembalikan daftar kosong bila belum pernah menyimpan.
  static Future<List<MataKuliahModel>> muatKrs() async {
    final prefs = await SharedPreferences.getInstance();
    final mentah = prefs.getString(kunciSimpan);
    if (mentah == null || mentah.isEmpty) return [];

    try {
      final daftarKode = List<String>.from(jsonDecode(mentah) as List);
      return katalogSemester5.where((m) => daftarKode.contains(m.kode)).toList();
    } on FormatException {
      // Isi penyimpanan rusak: bersihkan supaya aplikasi tetap bisa dipakai.
      await prefs.remove(kunciSimpan);
      return [];
    }
  }

  /// Simpan pilihan KRS ke penyimpanan lokal.
  static Future<void> simpanKrs(List<MataKuliahModel> dipilih) async {
    final prefs = await SharedPreferences.getInstance();
    final kode = dipilih.map((m) => m.kode).toList();
    await prefs.setString(kunciSimpan, jsonEncode(kode));
  }

  /// Hapus seluruh isi KRS.
  static Future<void> kosongkanKrs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kunciSimpan);
  }
}
