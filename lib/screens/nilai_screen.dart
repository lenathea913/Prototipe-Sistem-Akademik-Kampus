// lib/screens/nilai_screen.dart

import 'package:flutter/material.dart';
import '../data/data_lokal.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class NilaiScreen extends StatefulWidget {
  const NilaiScreen({super.key});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  final ApiService _apiService = ApiService();
  List<NilaiModel> _nilaiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNilai();
  }

  // ============================================
  // LOAD DATA NILAI
  // ============================================
  Future<void> _loadNilai() async {
    setState(() => _isLoading = true);

    // Coba ambil dari server lebih dulu. Bila server tidak membalas,
    // pakai data lokal dari lib/data/data_lokal.dart supaya prototipe
    // tetap bisa dijalankan tanpa backend.
    final dariServer = await _apiService.getNilai();
    _nilaiList = dariServer.isNotEmpty
        ? dariServer
        : nilaiLokal()
            .map((m) => NilaiModel.fromJson(m))
            .toList();

    setState(() => _isLoading = false);
  }

  // ============================================
  // HITUNG IPK
  // ============================================
  double get _ipk {
    if (_nilaiList.isEmpty) return 0;
    double totalNilai = _nilaiList.fold(0, (sum, n) => sum + n.finalGrade);
    return totalNilai / _nilaiList.length;
  }

  int get _totalSKS {
    return _nilaiList.fold(0, (sum, n) => sum + n.sks);
  }

  // ============================================
  // DAPATKAN WARNA BERDASARKAN NILAI
  // ============================================
  Color _getGradeColor(double grade) {
    if (grade >= 85) return AppColors.successColor;
    if (grade >= 75) return AppColors.accentColor;
    if (grade >= 65) return AppColors.warningColor;
    return AppColors.errorColor;
  }

  String _getLetterGrade(double grade) {
    if (grade >= 85) return 'A';
    if (grade >= 80) return 'A-';
    if (grade >= 75) return 'B+';
    if (grade >= 70) return 'B';
    if (grade >= 65) return 'B-';
    if (grade >= 60) return 'C+';
    if (grade >= 55) return 'C';
    return 'D';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Nilai'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNilai,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ============================================
                  // KARTU RINGKASAN IPK
                  // ============================================
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Indeks Prestasi Kumulatif',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _ipk.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total SKS: $_totalSKS',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============================================
                  // DAFTAR NILAI PER MATA KULIAH
                  // ============================================
                  const Text(
                    'Detail Nilai',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._nilaiList.map((nilai) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getGradeColor(nilai.finalGrade),
                        child: Text(
                          _getLetterGrade(nilai.finalGrade),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        nilai.mataKuliah,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'SKS: ${nilai.sks} • Status: ${nilai.status}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildNilaiRow('Tugas', nilai.tugas),
                              _buildNilaiRow('UTS', nilai.uts),
                              _buildNilaiRow('UAS', nilai.uas),
                              const Divider(),
                              _buildNilaiRow(
                                'Nilai Akhir',
                                nilai.finalGrade,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
    );
  }

  // ============================================
  // WIDGET BARIS NILAI
  // ============================================
  Widget _buildNilaiRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: _getGradeColor(value),
            ),
          ),
        ],
      ),
    );
  }
}
