// lib/models/user_model.dart

class UserModel {
  final int id;
  final String nim;
  final String nama;
  final String email;
  final String prodi;
  final String fakultas;
  final int semester;
  final String angkatan;
  final String fotoUrl;

  UserModel({
    required this.id,
    required this.nim,
    required this.nama,
    required this.email,
    required this.prodi,
    required this.fakultas,
    required this.semester,
    required this.angkatan,
    required this.fotoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      nim: json['nim'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      prodi: json['prodi'] ?? '',
      fakultas: json['fakultas'] ?? '',
      semester: json['semester'] ?? 1,
      angkatan: json['angkatan'] ?? '',
      fotoUrl: json['foto_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nim': nim,
      'nama': nama,
      'email': email,
      'prodi': prodi,
      'fakultas': fakultas,
      'semester': semester,
      'angkatan': angkatan,
      'foto_url': fotoUrl,
    };
  }
}

class JadwalModel {
  final int id;
  final String mataKuliah;
  final String dosen;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String ruangan;
  final int sks;

  JadwalModel({
    required this.id,
    required this.mataKuliah,
    required this.dosen,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruangan,
    required this.sks,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    return JadwalModel(
      id: json['id'] ?? 0,
      mataKuliah: json['mata_kuliah'] ?? '',
      dosen: json['dosen'] ?? '',
      hari: json['hari'] ?? '',
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
      ruangan: json['ruangan'] ?? '',
      sks: json['sks'] ?? 0,
    );
  }
}

class NilaiModel {
  final int id;
  final String mataKuliah;
  final int sks;
  final double uts;
  final double uas;
  final double tugas;
  final double finalGrade;
  final String status;

  NilaiModel({
    required this.id,
    required this.mataKuliah,
    required this.sks,
    required this.uts,
    required this.uas,
    required this.tugas,
    required this.finalGrade,
    required this.status,
  });

  factory NilaiModel.fromJson(Map<String, dynamic> json) {
    return NilaiModel(
      id: json['id'] ?? 0,
      mataKuliah: json['mata_kuliah'] ?? '',
      sks: json['sks'] ?? 0,
      uts: (json['uts'] ?? 0).toDouble(),
      uas: (json['uas'] ?? 0).toDouble(),
      tugas: (json['tugas'] ?? 0).toDouble(),
      finalGrade: (json['final_grade'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

class PresensiModel {
  final int id;
  final String mataKuliah;
  final String tanggal;
  final String status;
  final String keterangan;

  PresensiModel({
    required this.id,
    required this.mataKuliah,
    required this.tanggal,
    required this.status,
    required this.keterangan,
  });

  factory PresensiModel.fromJson(Map<String, dynamic> json) {
    return PresensiModel(
      id: json['id'] ?? 0,
      mataKuliah: json['mata_kuliah'] ?? '',
      tanggal: json['tanggal'] ?? '',
      status: json['status'] ?? '',
      keterangan: json['keterangan'] ?? '',
    );
  }
}
