// lib/utils/waktu.dart

/// Utilitas waktu untuk pengecekan bentrok jadwal dan penentuan hari.
library;


/// Nama hari pada kalender Gregorian, diurutkan sesuai [DateTime.weekday]
/// sehingga `namaHari[weekday - 1]` selalu aman untuk hari apa pun,
/// termasuk Minggu.
const List<String> namaHari = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

/// Nama hari untuk tanggal [tanggal], misalnya 'Senin' atau 'Minggu'.
String hariUntuk(DateTime tanggal) => namaHari[tanggal.weekday - 1];

/// Seluruh fungsi di berkas ini murni (tanpa Flutter) sehingga bisa diuji
/// unit test langsung tanpa widget.

/// Ubah "08:30" menjadi jumlah menit sejak tengah malam, yaitu 510.
///
/// Melempar [FormatException] bila format bukan "HH:MM" atau angkanya tidak
/// berada di rentang yang valid.
int menitDariJam(String jam) {
  final bagian = jam.split(':');
  if (bagian.length != 2) {
    throw FormatException('Format jam tidak sah: "$jam" (harus HH:MM)');
  }

  final j = int.tryParse(bagian[0].trim());
  final m = int.tryParse(bagian[1].trim());
  if (j == null || m == null) {
    throw FormatException('Format jam tidak sah: "$jam" (harus HH:MM)');
  }
  if (j < 0 || j > 23 || m < 0 || m > 59) {
    throw FormatException('Angka jam di luar rentang: "$jam"');
  }
  return j * 60 + m;
}

/// True bila dua rentang waktu saling tumpang tindih.
///
/// Rentang diperlakukan setengah terbuka, jadi kelas yang selesai tepat pada
/// jam mulai kelas lain **tidak** dianggap bentrok:
///
/// ```
/// bentrok("08:00","10:00","09:00","11:00") -> true
/// bentrok("08:00","10:00","10:00","12:00") -> false
/// ```
bool rentangWaktuBentrok(
  String mulaiA,
  String selesaiA,
  String mulaiB,
  String selesaiB,
) {
  final aMulai = menitDariJam(mulaiA);
  final aSelesai = menitDariJam(selesaiA);
  final bMulai = menitDariJam(mulaiB);
  final bSelesai = menitDariJam(selesaiB);

  if (aSelesai <= aMulai || bSelesai <= bMulai) {
    throw const FormatException('Jam selesai harus lebih besar daripada jam mulai');
  }

  return aMulai < bSelesai && bMulai < aSelesai;
}
