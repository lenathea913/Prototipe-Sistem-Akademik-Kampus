// lib/screens/presensi_screen.dart

import 'package:flutter/material.dart';
import '../data/data_lokal.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  final ApiService _apiService = ApiService();
  List<PresensiModel> _presensiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresensi();
  }

  Future<void> _loadPresensi() async {
    setState(() => _isLoading = true);

    // Coba ambil dari server lebih dulu. Bila server tidak membalas,
    // pakai data lokal dari lib/data/data_lokal.dart supaya prototipe
    // tetap bisa dijalankan tanpa backend.
    final dariServer = await _apiService.getPresensiHistory();
    _presensiList = dariServer.isNotEmpty
        ? dariServer
        : presensiLokal()
            .map((m) => PresensiModel.fromJson(m))
            .toList();

    setState(() => _isLoading = false);
  }

  // ============================================
  // DAPATKAN WARNA STATUS
  // ============================================
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return AppColors.successColor;
      case 'terlambat':
        return AppColors.warningColor;
      case 'alpha':
        return AppColors.errorColor;
      case 'izin':
        return AppColors.accentColor;
      case 'sakit':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ============================================
  // DAPATKAN IKON STATUS
  // ============================================
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return Icons.check_circle;
      case 'terlambat':
        return Icons.access_time;
      case 'alpha':
        return Icons.cancel;
      case 'izin':
        return Icons.info;
      case 'sakit':
        return Icons.medical_services;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Presensi'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPresensi,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _presensiList.length,
                itemBuilder: (context, index) {
                  final presensi = _presensiList[index];
                  final statusColor = _getStatusColor(presensi.status);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getStatusIcon(presensi.status),
                          color: statusColor,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        presensi.mataKuliah,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            presensi.tanggal,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            presensi.keterangan,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          presensi.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
