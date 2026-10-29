// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';

import '../data/data_lokal.dart';
import '../data/katalog_akademik.dart';
import '../models/matakuliah_model.dart';
import '../services/krs_service.dart';
import '../utils/constants.dart';
import '../utils/waktu.dart';
import '../widgets/custom_widgets.dart';
import 'jadwal_screen.dart';
import 'krs_screen.dart';
import 'nilai_screen.dart';
import 'presensi_screen.dart';
import 'profil_screen.dart';

/// Layar utama aplikasi setelah login, berisi lima tab:
/// Beranda, Jadwal, KRS, Nilai, dan Profil.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Beranda disimpan dalam kunci global supaya isinya bisa dimuat ulang ketika
  // pengguna kembali dari tab KRS dengan pilihan yang sudah berubah.
  final GlobalKey<HomeTabState> _kunciBeranda = GlobalKey<HomeTabState>();

  void _pindahTab(int index) {
    // Muat ulang ringkasan setiap kali Beranda dibuka, karena isi KRS bisa
    // berubah di tab sebelahnya.
    if (index == 0) _kunciBeranda.currentState?.muatUlang();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(
            key: _kunciBeranda,
            onBukaKrs: () => _pindahTab(2),
          ),
          const JadwalScreen(),
          const KrsScreen(),
          const NilaiScreen(),
          const ProfilScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _pindahTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_add_check),
            label: 'KRS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grade),
            label: 'Nilai',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ============================================
// HOME TAB - Beranda Utama
// ============================================
class HomeTab extends StatefulWidget {
  /// Dipanggil ketika pengguna menekan pintasan menuju halaman KRS.
  final VoidCallback onBukaKrs;

  const HomeTab({super.key, required this.onBukaKrs});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  final List<MataKuliahModel> _krs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    muatUlang();
  }

  /// Muat ulang isi KRS dari penyimpanan lokal.
  Future<void> muatUlang() async {
    setState(() => _isLoading = true);
    final tersimpan = await KrsService.muatKrs();
    if (!mounted) return;
    setState(() {
      _krs
        ..clear()
        ..addAll(tersimpan);
      _isLoading = false;
    });
  }

  /// Jadwal yang harus dihadiri hari ini, mengikuti KRS mahasiswa.
  ///
  /// Hari Minggu tidak punya kelas, jadi hasilnya kosong pada hari itu.
  List<MataKuliahModel> get _jadwalHariIni {
    final hariIni = hariUntuk(DateTime.now());
    return _krs.where((m) => m.hari == hariIni).toList();
  }

  static const List<Color> _warnaAksen = [
    AppColors.primaryColor,
    AppColors.successColor,
    AppColors.warningColor,
    AppColors.accentColor,
  ];

  @override
  Widget build(BuildContext context) {
    final totalSks = KrsService.totalSks(_krs);
    final sisaKuota = KrsService.batasSks - totalSks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KampusKu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // HEADER - Selamat Datang
                  // ============================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.secondaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat Datang,',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mahasiswaContoh.nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mahasiswaContoh.prodi} • '
                          'Semester ${mahasiswaContoh.semester}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============================================
                  // STATISTIK RINGKASAN (berasal dari KRS nyata)
                  // ============================================
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Ringkasan Akademik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'Total SKS Diambil',
                            value: '$totalSks',
                            icon: Icons.menu_book,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InfoCard(
                            title: 'Sisa Kuota SKS',
                            value: '$sisaKuota',
                            icon: Icons.hourglass_bottom,
                            color: sisaKuota > 0
                                ? AppColors.successColor
                                : AppColors.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'Jumlah Mata Kuliah',
                            value: '${_krs.length}',
                            icon: Icons.library_books,
                            color: AppColors.accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: InfoCard(
                            title: 'Batas Maksimum',
                            value: '${KrsService.batasSks}',
                            icon: Icons.speed,
                            color: AppColors.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============================================
                  // MENU UTAMA (4 Menu Grid)
                  // ============================================
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Menu Utama',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        MenuCard(
                          title: 'Isi\nKRS',
                          icon: Icons.playlist_add_check,
                          color: AppColors.primaryColor,
                          onTap: widget.onBukaKrs,
                        ),
                        MenuCard(
                          title: 'Jadwal\nKuliah',
                          icon: Icons.schedule,
                          color: AppColors.accentColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const JadwalScreen(),
                              ),
                            );
                          },
                        ),
                        MenuCard(
                          title: 'Lihat\nNilai',
                          icon: Icons.grade,
                          color: AppColors.successColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NilaiScreen(),
                              ),
                            );
                          },
                        ),
                        MenuCard(
                          title: 'Profil\nSaya',
                          icon: Icons.person,
                          color: AppColors.warningColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============================================
                  // JADWAL HARI INI
                  // ============================================
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Jadwal Hari Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_jadwalHariIni.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Tidak ada kelas hari ini. Buka tab KRS untuk '
                        'memilih mata kuliah.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...List.generate(_jadwalHariIni.length, (index) {
                      final matkul = _jadwalHariIni[index];
                      return ScheduleTile(
                        mataKuliah: matkul.nama,
                        dosen: matkul.dosen,
                        waktu: matkul.rentangJam,
                        ruangan: matkul.ruangan,
                        accentColor:
                            _warnaAksen[index % _warnaAksen.length],
                      );
                    }),

                  const SizedBox(height: 24),

                  // ============================================
                  // RINGKASAN KEHADIRAN -> RIWAYAT PRESENSI
                  // ============================================
                  // Pintasan ke PresensiScreen: layar presensi sudah ada
                  // sejak Tahap 3 tetapi belum pernah bisa dibuka dari UI.
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Kehadiran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fact_check,
                            color: AppColors.successColor,
                          ),
                        ),
                        title: const Text(
                          'Riwayat Presensi',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Kehadiran ${hitungKehadiran(presensiLokal())}% '
                          'dua pekan terakhir',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PresensiScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
