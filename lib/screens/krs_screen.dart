// lib/screens/krs_screen.dart

import 'package:flutter/material.dart';

import '../data/katalog_akademik.dart';
import '../models/matakuliah_model.dart';
import '../services/krs_service.dart';
import '../utils/constants.dart';
import '../utils/waktu.dart';

/// Halaman pengisian Kartu Rencana Studi.
///
/// Menampilkan seluruh mata kuliah yang ditawarkan pada semester berjalan
/// beserta status centangnya. Aturan yang diterapkan:
///
///  * total SKS tidak boleh melebihi [KrsService.batasSks] (24 SKS);
///  * mata kuliah yang waktunya tumpang tindih dengan pilihan yang sudah ada
///    tidak boleh dipilih.
///
/// Kedua aturan ditolak sejak dari percobaan pemilihan, bukan ketika menyimpan,
/// supaya mahasiswa langsung mendapat umpan balik.
class KrsScreen extends StatefulWidget {
  const KrsScreen({super.key});

  @override
  State<KrsScreen> createState() => _KrsScreenState();
}

class _KrsScreenState extends State<KrsScreen> {
  final List<MataKuliahModel> _dipilih = [];
  List<MataKuliahModel> _katalog = [];
  bool _isLoading = true;
  String? _pesanTerakhir;
  bool _pesanAdalahGalat = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _isLoading = true);

    final tersimpan = await KrsService.muatKrs();
    // Katalog disaring supaya hanya mata kuliah yang tersedia yang tampil.
    // Urutan mengikuti `urutkanJadwal` agar tidak berubah-ubah.
    final katalog = urutkanJadwal(List.of(katalogSemester5));

    if (!mounted) return;
    setState(() {
      _katalog = katalog;
      _dipilih
        ..clear()
        ..addAll(tersimpan);
      _isLoading = false;
    });
  }

  int get _totalSks => KrsService.totalSks(_dipilih);
  int get _sisaKuota => KrsService.batasSks - _totalSks;

  MataKuliahModel? _matkulTerpilih(String kode) {
    for (final m in _dipilih) {
      if (m.kode == kode) return m;
    }
    return null;
  }

  void _tampilkanPesan(String pesan, {bool galat = false}) {
    if (!mounted) return;
    setState(() {
      _pesanTerakhir = pesan;
      _pesanAdalahGalat = galat;
    });
  }

  /// Tambah atau hapus satu mata kuliah dari KRS.
  void _ubahPilihan(MataKuliahModel matkul, bool? centang) {
    final mauDipilih = centang ?? false;

    if (!mauDipilih) {
      setState(() => _dipilih.removeWhere((m) => m.kode == matkul.kode));
      return;
    }

    final hasil = KrsService.validasiTambah(
      kode: matkul.kode,
      dipilih: _dipilih,
      katalog: _katalog,
    );

    if (!hasil.diperbolehkan) {
      _tampilkanPesan(
        KrsService.pesanDari(
          hasil,
          kandidat: matkul,
          dipilih: _dipilih,
        ),
        galat: true,
      );
      return;
    }

    setState(() => _dipilih.add(matkul));
    _tampilkanPesan(
      '${matkul.nama} (${matkul.sks} SKS) ditambahkan. Sisa kuota $_sisaKuota SKS.',
    );
  }

  /// Simpan KRS ke penyimpanan lokal.
  Future<void> _simpan() async {
    // Validasi ulang seluruh isi KRS sebelum menyimpan. Meskipun penambahan
    // sudah divalidasi satu per satu, pemeriksaan akhir ini menangkap kasus
    // data katalog berubah di tengah jalan.
    for (final matkul in _dipilih) {
      final hasil = KrsService.validasiTambah(
        kode: matkul.kode,
        dipilih: _dipilih.where((m) => m.kode != matkul.kode).toList(),
        katalog: _katalog,
      );
      if (hasil.status == StatusTambah.bentrokJadwal) {
        _tampilkanPesan(
          KrsService.pesanDari(hasil, kandidat: matkul, dipilih: _dipilih),
          galat: true,
        );
        return;
      }
    }

    await KrsService.simpanKrs(_dipilih);
    if (!mounted) return;

    final hariIni = hariUntuk(DateTime.now());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'KRS tersimpan: ${_dipilih.length} mata kuliah, $_totalSks SKS. '
          'Jadwal berlaku mulai $hariIni.',
        ),
        backgroundColor: AppColors.successColor,
      ),
    );
    _tampilkanPesan('KRS berhasil disimpan.');
  }

  Future<void> _kosongkan() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan KRS'),
        content: const Text(
          'Seluruh mata kuliah yang dipilih akan dihapus dari KRS. '
          'Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Kosongkan',
              style: TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;
    await KrsService.kosongkanKrs();
    if (!mounted) return;
    setState(() => _dipilih.clear());
    _tampilkanPesan('KRS dikosongkan.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengisian KRS'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Kosongkan KRS',
            onPressed: _dipilih.isEmpty ? null : _kosongkan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _ringkasan(),
                if (_pesanTerakhir != null) _bannerPesan(),
                _daftarMataKuliah(),
              ],
            ),
      bottomNavigationBar: _bilahSimpan(),
    );
  }

  // ============================================
  // RINGKASAN BATAS SKS
  // ============================================
  Widget _ringkasan() {
    // Kuota diwarnai merah ketika tersisa sedikit, hijau ketika masih lega.
    final rasio = _totalSks / KrsService.batasSks;
    final warnaKuota = rasio >= 1.0
        ? AppColors.errorColor
        : rasio >= 0.75
            ? AppColors.warningColor
            : AppColors.successColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total SKS Diambil',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Batas ${KrsService.batasSks} SKS',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_totalSks',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: warnaKuota,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  ' / ${KrsService.batasSks} SKS',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_dipilih.length} mata kuliah',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rasio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(warnaKuota),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _sisaKuota > 0
                ? 'Sisa kuota $_sisaKuota SKS lagi.'
                : 'Kuota penuh. Lepas satu mata kuliah untuk memilih yang lain.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _sisaKuota > 0
                  ? AppColors.textSecondary
                  : AppColors.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BANNER PESAN / GALAT TERAKHIR
  // ============================================
  Widget _bannerPesan() {
    final warna = _pesanAdalahGalat
        ? AppColors.errorColor
        : AppColors.successColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: warna.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            _pesanAdalahGalat ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: warna,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _pesanTerakhir ?? '',
              style: TextStyle(fontSize: 12.5, color: warna),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _pesanTerakhir = null),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DAFTAR MATA KULIAH
  // ============================================
  Widget _daftarMataKuliah() {
    if (_katalog.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Tidak ada mata kuliah yang ditawarkan.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _katalog.length,
        itemBuilder: (context, index) {
          final matkul = _katalog[index];
          final terpilih = _matkulTerpilih(matkul.kode) != null;
          final bentrok = terpilih ? null : KrsService.cariBentrok(matkul, _dipilih);
          final kuotaPenuh =
              !terpilih && _totalSks + matkul.sks > KrsService.batasSks;
          final bisaDipilih = !terpilih && bentrok == null && !kuotaPenuh;

          // Kelas yang bentrok atau kehabisan kuota sengaja tetap bisa
          // ditekan. Menonaktifkan kotak centang membuat pengguna tidak
          // tahu apa yang salah; dengan tetap aktif, penekanan akan
          // memunculkan pesan penolakan yang menjelaskan alasannya.
          final aktif = terpilih || bisaDipilih || bentrok != null || kuotaPenuh;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: CheckboxListTile(
              value: terpilih,
              onChanged: aktif ? (centang) => _ubahPilihan(matkul, centang) : null,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primaryColor,
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      matkul.nama,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: bisaDipilih || terpilih
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${matkul.sks} SKS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${matkul.kode} • ${matkul.dosen}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${matkul.hari}, ${matkul.rentangJam}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.room, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        matkul.ruangan,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (bentrok != null) _labelAlasan('BENTROK: ${bentrok.nama}'),
                  if (bentrok == null && kuotaPenuh)
                    _labelAlasan('KUOTA SKS PENUH'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _labelAlasan(String teks) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        teks,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.errorColor,
        ),
      ),
    );
  }

  // ============================================
  // BILAH AKSI SIMPAN
  // ============================================
  Widget _bilahSimpan() {
    final adaIsi = _dipilih.isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                adaIsi
                    ? '${_dipilih.length} MK • $_totalSks SKS'
                    : 'Belum ada pilihan',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: adaIsi ? _simpan : null,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Simpan KRS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
