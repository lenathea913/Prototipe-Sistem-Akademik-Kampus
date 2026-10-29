// lib/data/data_lokal.dart

import '../models/user_model.dart';
import '../utils/waktu.dart';
import 'katalog_akademik.dart';

/// Data akademik cadangan yang dipakai ketika backend pada
/// `AppConstants.baseUrl` tidak dapat dihubungi.
///
/// Sumber data ini bukan sekadar hiasan: prototipe Tahap 3 memang dijalankan
/// tanpa server, jadi seluruh layar (jadwal, nilai, presensi, KRS) tetap
/// menampilkan isi yang masuk akal. Begitu backend tersedia, permintaan HTTP
/// yang berhasil akan menimpa data di sini.
///
/// Daftar nilai dan presensi sengaja dibuat mengikuti katalog mata kuliah,
/// bukan daftar terpisah, supaya jumlah SKS dan nama mata kuliah tidak pernah
/// berbeda antar layar.

/// Jadwal kuliah = katalog semester berjalan.
///
/// Kunci `id` dan `mata_kuliah` ditambahkan di sini karena itulah bentuk yang
/// dibaca `JadwalModel.fromJson`; katalog model sendiri memakai `nama`.
List<Map<String, dynamic>> jadwalLokal() {
  var urut = 0;
  return katalogSemester5.map((m) {
    return {
      'id': ++urut,
      ...m.toJson(),
      'mata_kuliah': m.nama,
    };
  }).toList();
}

/// Daftar nilai akhir per mata kuliah.
///
/// [finalGrade] dihitung dari komponen penilaian (tugas 30%, UTS 30%, UAS 40%)
/// memakai rumus yang sama dengan yang dipakai layar Nilai, supaya angka yang
/// tampil konsisten bila dikalikan ulang.
List<Map<String, dynamic>> nilaiLokal() {
  // Urutan tiap entri: [tugas, UTS, UAS].
  const komponen = <String, List<double>>{
    'IF3201': [90, 85, 88],
    'IF3202': [82, 78, 84],
    'IF3203': [88, 90, 92],
    'IF3204': [80, 75, 79],
    'IF3205': [87, 83, 85],
    'IF3206': [78, 80, 82],
    'IF3207': [91, 88, 90],
    'IF3208': [76, 72, 80],
    'IF3209': [84, 86, 88],
    'IF3210': [80, 84, 81],
    'IF3211': [89, 85, 87],
    'IF3212': [92, 90, 94],
  };

  final hasil = <Map<String, dynamic>>[];
  var urut = 0;

  for (final matkul in katalogSemester5) {
    final nilai = komponen[matkul.kode];
    if (nilai == null) continue;

    final tugas = nilai[0];
    final uts = nilai[1];
    final uas = nilai[2];
    final akhir = double.parse(
      (tugas * 0.3 + uts * 0.3 + uas * 0.4).toStringAsFixed(1),
    );

    hasil.add({
      'id': ++urut,
      'mata_kuliah': matkul.nama,
      'kode': matkul.kode,
      'sks': matkul.sks,
      'uts': uts,
      'uas': uas,
      'tugas': tugas,
      'final_grade': akhir,
      'status': akhir >= 60 ? 'Lulus' : 'Belum Lulus',
    });
  }

  return hasil;
}

/// Riwayat presensi dua minggu terakhir, dibuat mengikuti jadwal kuliah.
List<Map<String, dynamic>> presensiLokal() {
  final hasil = <Map<String, dynamic>>[];
  final hariIni = DateTime.now();
  var urut = 0;

  // Kembali 13 hari untuk menutupi dua pekan penuh, termasuk hari Minggu yang
  // tidak ada kelas.
  for (int mundur = 13; mundur >= 0; mundur--) {
    final tanggal = hariIni.subtract(Duration(days: mundur));
    // Minggu tidak ada kelas, jadi dilewati.
    if (tanggal.weekday > 6) continue;
    final hari = hariUntuk(tanggal);

    for (final matkul in katalogSemester5) {
      if (matkul.hari != hari) continue;

      // Status hadir diacak secara deterministik dari tanggal dan kode mata
      // kuliah supaya tampilan tidak berubah setiap kali aplikasi dibuka.
      final benih = (tanggal.day * 31 + matkul.kode.hashCode.abs()) % 10;
      final (status, keterangan) = switch (benih) {
        0 => ('Izin', 'Izin dosen wali'),
        1 => ('Sakit', 'Surat keterangan dokter'),
        2 => ('Terlambat', 'Terlambat 10 menit'),
        _ => ('Hadir', 'Tepat waktu'),
      };

      hasil.add({
        'id': ++urut,
        'mata_kuliah': matkul.nama,
        'kode': matkul.kode,
        'tanggal':
            '${tanggal.year}-${_duaDigit(tanggal.month)}-${_duaDigit(tanggal.day)}',
        'status': status,
        'keterangan': keterangan,
      });
    }
  }

  return hasil;
}

String _duaDigit(int nilai) => nilai.toString().padLeft(2, '0');

/// Hitung IPK dari daftar nilai, dibobot SKS.
double hitungIpk(List<Map<String, dynamic>> daftarNilai) {
  double totalBobot = 0;
  double totalNilai = 0;

  for (final n in daftarNilai) {
    final sks = (n['sks'] as num).toDouble();
    final akhir = (n['final_grade'] as num).toDouble();
    totalBobot += sks;
    totalNilai += akhir * sks;
  }

  if (totalBobot == 0) return 0;
  return double.parse((totalNilai / totalBobot / 25).toStringAsFixed(2));
}

/// Persentase kehadiran dari daftar presensi.
double hitungKehadiran(List<Map<String, dynamic>> daftarPresensi) {
  if (daftarPresensi.isEmpty) return 100;
  final hadir =
      daftarPresensi.where((p) => p['status'] == 'Hadir').length;
  return double.parse(
    (hadir / daftarPresensi.length * 100).toStringAsFixed(0),
  );
}

/// Profil mahasiswa yang dipakai ketika backend tidak tersedia.
UserModel profilLokal() => mahasiswaContoh;

/// NIM dan password yang diterima oleh mode autentikasi lokal.
///
/// Dipakai ketika backend tidak dapat dihubungi supaya prototipe tetap bisa
/// dijalankan. Kredensial ditampilkan pada layar login.
const String kNimDemo = '240605110150';
const String kSandiDemo = 'kampusku123';
