// lib/screens/jadwal_screen.dart

import 'package:flutter/material.dart';
import '../data/data_lokal.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_widgets.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final ApiService _apiService = ApiService();
  List<JadwalModel> _jadwalList = [];
  bool _isLoading = true;
  String _selectedDay = 'Semua';

  final List<String> _days = [
    'Semua', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
  ];

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  // ============================================
  // LOAD DATA JADWAL
  // ============================================
  Future<void> _loadJadwal() async {
    setState(() => _isLoading = true);

    // Coba ambil dari server lebih dulu. Bila server tidak membalas,
    // pakai data lokal dari lib/data/data_lokal.dart supaya prototipe
    // tetap bisa dijalankan tanpa backend.
    final dariServer = await _apiService.getJadwal();
    _jadwalList = dariServer.isNotEmpty
        ? dariServer
        : jadwalLokal()
            .map((m) => JadwalModel.fromJson(m))
            .toList();

    setState(() => _isLoading = false);
  }

  // ============================================
  // FILTER JADWAL BERDASARKAN HARI
  // ============================================
  List<JadwalModel> get _filteredJadwal {
    if (_selectedDay == 'Semua') return _jadwalList;
    return _jadwalList.where((j) => j.hari == _selectedDay).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kuliah'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ============================================
          // FILTER HARI
          // ============================================
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                final isSelected = _selectedDay == day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedDay = day);
                    },
                    selectedColor: AppColors.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ============================================
          // LIST JADWAL
          // ============================================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredJadwal.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada jadwal',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadJadwal,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredJadwal.length,
                          itemBuilder: (context, index) {
                            final jadwal = _filteredJadwal[index];
                            return ScheduleTile(
                              mataKuliah: jadwal.mataKuliah,
                              dosen: jadwal.dosen,
                              waktu: '${jadwal.jamMulai} - ${jadwal.jamSelesai}',
                              ruangan: jadwal.ruangan,
                              accentColor: _getAccentColor(index),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Color _getAccentColor(int index) {
    final colors = [
      AppColors.primaryColor,
      AppColors.successColor,
      AppColors.warningColor,
      AppColors.accentColor,
      AppColors.errorColor,
    ];
    return colors[index % colors.length];
  }
}
