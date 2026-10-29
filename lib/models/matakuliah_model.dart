// lib/models/matakuliah_model.dart

import '../utils/waktu.dart';

/// Model satu mata kuliah yang ditawarkan pada sebuah semester.
///
/// Dipakai untuk dua keperluan sekaligus: katalog mata kuliah yang boleh
/// dipilih mahasiswa, dan isi KRS yang sudah tersimpan.
class MataKuliahModel {
  final String kode;
  final String nama;
  final int sks;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String ruangan;
  final String dosen;

  const MataKuliahModel({
    required this.kode,
    required this.nama,
    required this.sks,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruangan,
    required this.dosen,
  });

  /// "08:00 - 10:00"
  String get rentangJam => '$jamMulai - $jamSelesai';

  /// Dua mata kuliah bentrok bila hari sama dan rentang waktunya tumpang tindih.
  ///
  /// Dua kelas yang bersentuhan (kelas A selesai tepat saat kelas B mulai)
  /// **tidak** dianggap bentrok.
  bool bentrokDengan(MataKuliahModel lain) {
    if (hari != lain.hari) return false;
    return rentangWaktuBentrok(
      jamMulai,
      jamSelesai,
      lain.jamMulai,
      lain.jamSelesai,
    );
  }

  factory MataKuliahModel.fromJson(Map<String, dynamic> json) {
    return MataKuliahModel(
      kode: json['kode'] ?? '',
      nama: json['nama'] ?? '',
      sks: json['sks'] ?? 0,
      hari: json['hari'] ?? '',
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
      ruangan: json['ruangan'] ?? '',
      dosen: json['dosen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kode': kode,
      'nama': nama,
      'sks': sks,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'ruangan': ruangan,
      'dosen': dosen,
    };
  }
}
