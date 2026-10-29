// lib/services/api_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/data_lokal.dart';
import '../models/matakuliah_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Lapisan akses data akademik.
///
/// Setiap metode berusaha menghubungi backend pada [AppConstants.baseUrl]
/// lebih dulu. Bila server tidak dapat dihubungi atau membalas bukan 200,
/// permintaan dianggap gagal dan metode mengembalikan [dataLokal] supaya
/// prototipe tetap dapat dijalankan tanpa server.
///
/// Waktu tunggu dibatasi oleh [timeout] agar aplikasi tidak menggantung
/// ketika alamat server tidak ada di jaringan.
class ApiService {
  /// Batas waktu tunggu respons server.
  static const Duration timeout = Duration(seconds: 4);

  // GET Token dari Local Storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // Headers dengan Authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET JSON dari [endpoint], atau null bila server tidak dapat dihubungi.
  ///
  /// Null berarti "tidak ada data dari server", bukan "server bilang kosong",
  /// sehingga pemanggil masih boleh memakai data lokal.
  Future<Map<String, dynamic>?> _getJson(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}$endpoint'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      // Timeout, DNS gagal, atau respons bukan JSON. Semua diperlakukan sama:
      // jatuh ke data lokal.
      return null;
    }
  }

  // ============================================
  // LOGIN
  // ============================================
  /// Autentikasi pengguna.
  ///
  /// Mengembalikan peta berisi `success`, `message`, dan bila berhasil juga
  /// `data` berisi profil pengguna.
  Future<Map<String, dynamic>> login(String nim, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nim': nim, 'password': password}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = UserModel.fromJson(
          (data['user'] ?? const {}) as Map<String, dynamic>,
        );

        // Simpan token ke local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, data['token'] ?? '');
        await prefs.setInt(AppConstants.userIdKey, user.id);
        await prefs.setString(AppConstants.userNameKey, user.nama);
        await prefs.setString(AppConstants.userNimKey, user.nim);

        return {'success': true, 'message': 'Login berhasil', 'data': user};
      }

      // Server hidup dan menolak kredensial: jangan ganti dengan data lokal,
      // karena itu akan menyembunyikan kesalahan kata sandi yang sebenarnya.
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': false,
        'message': data['message'] ?? 'Login gagal',
      };
    } catch (_) {
      // Server tidak terjangkau: gunakan mode autentikasi lokal.
      return _loginLokal(nim, password);
    }
  }

  /// Autentikasi lokal untuk prototipe tanpa backend.
  ///
  /// Hanya menerima kredensial pada [kNimDemo]/[kSandiDemo]. Kegagalan kredensial
  /// tetap dilaporkan sebagai kegagalan, bukan dianggap berhasil.
  Future<Map<String, dynamic>> _loginLokal(String nim, String password) async {
    if (nim != kNimDemo || password != kSandiDemo) {
      return {
        'success': false,
        'message': 'NIM atau kata sandi salah. '
            'Gunakan $kNimDemo / $kSandiDemo untuk mode prototipe.',
      };
    }

    final user = profilLokal();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, 'token-lokal');
    await prefs.setInt(AppConstants.userIdKey, user.id);
    await prefs.setString(AppConstants.userNameKey, user.nama);
    await prefs.setString(AppConstants.userNimKey, user.nim);

    return {'success': true, 'message': 'Login berhasil', 'data': user};
  }

  // ============================================
  // GET PROFILE
  // ============================================
  Future<UserModel?> getProfile() async {
    final data = await _getJson(AppConstants.profileEndpoint);
    if (data == null || data['data'] == null) return null;
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ============================================
  // GET JADWAL
  // ============================================
  Future<List<JadwalModel>> getJadwal() async {
    final data = await _getJson(AppConstants.jadwalEndpoint);
    if (data == null || data['data'] is! List) return [];
    return (data['data'] as List)
        .map((j) => JadwalModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ============================================
  // GET MATA KULIAH (katalog untuk KRS)
  // ============================================
  Future<List<MataKuliahModel>> getKatalog() async {
    final data = await _getJson(AppConstants.matkulEndpoint);
    if (data == null || data['data'] is! List) return [];
    return (data['data'] as List)
        .map((m) => MataKuliahModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  // ============================================
  // GET NILAI
  // ============================================
  Future<List<NilaiModel>> getNilai() async {
    final data = await _getJson(AppConstants.nilaiEndpoint);
    if (data == null || data['data'] is! List) return [];
    return (data['data'] as List)
        .map((n) => NilaiModel.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  // ============================================
  // POST PRESENSI
  // ============================================
  Future<Map<String, dynamic>> postPresensi(int jadwalId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}${AppConstants.presensiEndpoint}'),
            headers: headers,
            body: jsonEncode({'jadwal_id': jadwalId, 'status': status}),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Presensi berhasil'};
      }
      return {'success': false, 'message': 'Presensi gagal'};
    } catch (_) {
      return {'success': false, 'message': 'Server presensi tidak terjangkau.'};
    }
  }

  // ============================================
  // GET PRESENSI HISTORY
  // ============================================
  Future<List<PresensiModel>> getPresensiHistory() async {
    final data = await _getJson('${AppConstants.presensiEndpoint}/history');
    if (data == null || data['data'] is! List) return [];
    return (data['data'] as List)
        .map((p) => PresensiModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  // ============================================
  // LOGOUT
  // ============================================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Hapus kredensial sesi saja; pilihan KRS sengaja dipertahankan supaya
    // mahasiswa tidak kehilangan isi KRS hanya karena keluar dan masuk lagi.
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userNimKey);
  }
}
