// lib/screens/profil_screen.dart

import 'package:flutter/material.dart';
import '../data/data_lokal.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Coba ambil profil dari server lebih dulu; bila server tidak terjangkau,
    // gunakan profil lokal dari lib/data/data_lokal.dart.
    final user = await _apiService.getProfile();

    if (!mounted) return;
    setState(() {
      _user = user ?? profilLokal();
      _isLoading = false;
    });
  }

  // ============================================
  // LOGOUT DENGAN KONFIRMASI
  // ============================================
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ============================================
                  // FOTO PROFIL
                  // ============================================
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      _user!.nama.isNotEmpty ? _user!.nama[0] : '?',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.nama,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: ${_user!.nim}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ============================================
                  // DETAIL INFORMASI
                  // ============================================
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoTile(
                            Icons.email,
                            'Email',
                            _user!.email,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            Icons.school,
                            'Program Studi',
                            _user!.prodi,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            Icons.business,
                            'Fakultas',
                            _user!.fakultas,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            Icons.calendar_today,
                            'Semester',
                            'Semester ${_user!.semester}',
                          ),
                          const Divider(),
                          _buildInfoTile(
                            Icons.access_time,
                            'Angkatan',
                            _user!.angkatan,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============================================
                  // MENU TAMBAHAN
                  // ============================================
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Pengaturan'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.help),
                          title: const Text('Bantuan'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('Tentang Aplikasi'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: AppConstants.appName,
                              applicationVersion: AppConstants.appVersion,
                              applicationIcon: const Icon(
                                Icons.school,
                                size: 48,
                                color: AppColors.primaryColor,
                              ),
                              children: [
                                const Text(
                                  'Aplikasi Sistem Informasi Akademik '
                                  'untuk mahasiswa Universitas Teknologi.',
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============================================
                  // TOMBOL LOGOUT
                  // ============================================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'KELUAR',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============================================
                  // VERSI APLIKASI
                  // ============================================
                  const Text(
                    '${AppConstants.appName} v${AppConstants.appVersion}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ============================================
  // WIDGET INFO TILE
  // ============================================
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
