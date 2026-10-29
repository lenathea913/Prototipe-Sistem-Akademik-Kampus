// lib/data/katalog_akademik.dart

import '../models/matakuliah_model.dart';
import '../models/user_model.dart';

/// Katalog mata kuliah yang ditawarkan pada Semester 5.
///
/// Karena backend pada `AppConstants.baseUrl` tidak tersedia pada prototipe
/// ini, katalog disimpan sebagai data lokal. Strukturnya sama persis dengan
/// yang dikembalikan endpoint `/matkul`, sehingga saat API tersedia cukup
/// menukar sumber data pada repository tanpa mengubah UI.
const List<MataKuliahModel> katalogSemester5 = [
  MataKuliahModel(
    kode: 'IF3201',
    nama: 'Pemrograman Mobile',
    sks: 3,
    hari: 'Senin',
    jamMulai: '08:00',
    jamSelesai: '10:00',
    ruangan: 'R.301',
    dosen: 'Dr. Budi Santoso, M.Kom',
  ),
  MataKuliahModel(
    kode: 'IF3202',
    nama: 'Basis Data Lanjut',
    sks: 3,
    hari: 'Senin',
    jamMulai: '10:15',
    jamSelesai: '12:15',
    ruangan: 'R.205',
    dosen: 'Siti Nurhaliza, M.T.',
  ),
  MataKuliahModel(
    kode: 'IF3203',
    nama: 'Jaringan Komputer',
    sks: 3,
    hari: 'Selasa',
    jamMulai: '08:00',
    jamSelesai: '10:00',
    ruangan: 'Lab.3',
    dosen: 'Ir. Andi Wijaya, M.Sc.',
  ),
  MataKuliahModel(
    kode: 'IF3204',
    nama: 'Kecerdasan Buatan',
    sks: 3,
    hari: 'Rabu',
    jamMulai: '08:00',
    jamSelesai: '10:00',
    ruangan: 'R.401',
    dosen: 'Prof. Dr. Hendra, S.Kom.',
  ),
  MataKuliahModel(
    kode: 'IF3205',
    nama: 'Rekayasa Perangkat Lunak',
    sks: 3,
    hari: 'Kamis',
    jamMulai: '09:00',
    jamSelesai: '11:00',
    ruangan: 'R.102',
    dosen: 'Maya Putri, M.Kom.',
  ),
  MataKuliahModel(
    kode: 'IF3206',
    nama: 'Manajemen Proyek TI',
    sks: 2,
    hari: 'Jumat',
    jamMulai: '10:00',
    jamSelesai: '12:00',
    ruangan: 'R.201',
    dosen: 'Dedi Kurniawan, M.Sc.',
  ),
  MataKuliahModel(
    kode: 'IF3207',
    nama: 'Pemrograman Web Lanjut',
    sks: 3,
    hari: 'Selasa',
    jamMulai: '10:15',
    jamSelesai: '12:15',
    ruangan: 'R.204',
    dosen: 'Rina Anggraini, S.Kom.',
  ),
  MataKuliahModel(
    kode: 'IF3208',
    nama: 'Statistika Terapan',
    sks: 3,
    hari: 'Rabu',
    jamMulai: '10:15',
    jamSelesai: '12:15',
    ruangan: 'R.105',
    dosen: 'Dr. Eng. Pakasi, M.Si.',
  ),
  MataKuliahModel(
    kode: 'IF3209',
    nama: 'Interaksi Manusia dan Komputer',
    sks: 2,
    hari: 'Kamis',
    jamMulai: '11:15',
    jamSelesai: '13:00',
    ruangan: 'R.102',
    dosen: 'Maya Putri, M.Kom.',
  ),
  MataKuliahModel(
    kode: 'IF3210',
    nama: 'Bahasa Inggris Teknis',
    sks: 2,
    hari: 'Jumat',
    jamMulai: '08:00',
    jamSelesai: '09:45',
    ruangan: 'R.201',
    dosen: 'Sri Wahyuni, M.Pd.',
  ),
  MataKuliahModel(
    kode: 'IF3211',
    nama: 'Keamanan Informasi',
    sks: 3,
    hari: 'Selasa',
    jamMulai: '08:00',
    jamSelesai: '10:00',
    ruangan: 'Lab.5',
    dosen: 'Ir. Andi Wijaya, M.Sc.',
  ),
  MataKuliahModel(
    kode: 'IF3212',
    nama: 'Pemrograman Backend',
    sks: 3,
    hari: 'Rabu',
    jamMulai: '08:00',
    jamSelesai: '10:00',
    ruangan: 'Lab.2',
    dosen: 'Prof. Dr. Hendra, S.Kom.',
  ),
];

/// Data mahasiswa yang dipakai ketika backend tidak dapat dihubungi.
///
/// NIM dan nama mengikuti identitas pemilik proyek, bukan tokoh rekaan,
/// supaya prototipe konsisten dengan dokumen Tahap 1 dan Tahap 2.
final UserModel mahasiswaContoh = UserModel(
  id: 1,
  nim: '240605110150',
  nama: 'Ryan Athallah Subekti',
  email: 'ryan.subekti@university.ac.id',
  prodi: 'Teknik Informatika',
  fakultas: 'Fakultas Ilmu Komputer',
  semester: 5,
  angkatan: '2024',
  fotoUrl: '',
);

/// Jadwal mingguan yang sedang berjalan, diurutkan per hari lalu per jam mulai.
///
/// Urutan penting: daftar KRS yang tampil dijadwalkan mengikuti urutan ini
/// supaya tampilan tidak berubah-ubah antar sesi.
List<MataKuliahModel> urutkanJadwal(List<MataKuliahModel> daftar) {
  const urutanHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  final hasil = List<MataKuliahModel>.from(daftar);

  hasil.sort((a, b) {
    final int indeksA = urutanHari.indexOf(a.hari);
    final int indeksB = urutanHari.indexOf(b.hari);
    if (indeksA != indeksB) return indeksA.compareTo(indeksB);
    return a.jamMulai.compareTo(b.jamMulai);
  });

  return hasil;
}
