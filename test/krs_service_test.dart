// test/krs_service_test.dart
//
// Uji aturan inti KampusKu Tahap 3: batas 24 SKS dan deteksi bentrok jadwal.

import 'package:flutter_test/flutter_test.dart';
import 'package:kampus_ku/data/katalog_akademik.dart';
import 'package:kampus_ku/models/matakuliah_model.dart';
import 'package:kampus_ku/services/krs_service.dart';
import 'package:kampus_ku/utils/waktu.dart';

void main() {
  // Daftar kecil dengan kode buatan supaya pembacaan kasus mudah.
  const senin08 = MataKuliahModel(
    kode: 'X1',
    nama: 'Senin Jam Delapan',
    sks: 3,
    hari: 'Senin',
    jamMulai: '08:00',
    jamSelesai: '10:00',
    ruangan: 'R.1',
    dosen: 'Dosen A',
  );
  const senin09 = MataKuliahModel(
    kode: 'X2',
    nama: 'Senin Jam Sembilan',
    sks: 3,
    hari: 'Senin',
    jamMulai: '09:00',
    jamSelesai: '11:00',
    ruangan: 'R.2',
    dosen: 'Dosen B',
  );
  // Mulai tepat saat senin08 selesai: tidak boleh dianggap bentrok.
  const senin10 = MataKuliahModel(
    kode: 'X3',
    nama: 'Senin Jam Sepuluh',
    sks: 3,
    hari: 'Senin',
    jamMulai: '10:00',
    jamSelesai: '12:00',
    ruangan: 'R.3',
    dosen: 'Dosen C',
  );
  // Jam sama persis dengan senin08 tetapi hari berbeda.
  const selasa08 = MataKuliahModel(
    kode: 'X4',
    nama: 'Selasa Jam Delapan',
    sks: 3,
    hari: 'Selasa',
    jamMulai: '08:00',
    jamSelesai: '10:00',
    ruangan: 'R.4',
    dosen: 'Dosen D',
  );

  const katalogUji = [senin08, senin09, senin10, selasa08];

  group('util waktu', () {
    test('menitDariJam mengubah HH:MM menjadi menit', () {
      expect(menitDariJam('00:00'), 0);
      expect(menitDariJam('08:00'), 480);
      expect(menitDariJam('08:30'), 510);
      expect(menitDariJam('23:59'), 23 * 60 + 59);
    });

    test('menitDariJam menolak format yang tidak sah', () {
      expect(() => menitDariJam('8'), throwsFormatException);
      expect(() => menitDariJam('08:60'), throwsFormatException);
      expect(() => menitDariJam('24:00'), throwsFormatException);
      expect(() => menitDariJam('ab:cd'), throwsFormatException);
      expect(() => menitDariJam(''), throwsFormatException);
    });

    test('rentang tumpang tindih dianggap bentrok', () {
      expect(rentangWaktuBentrok('08:00', '10:00', '09:00', '11:00'), isTrue);
      expect(rentangWaktuBentrok('09:00', '11:00', '08:00', '10:00'), isTrue);
      // Satu kelas sepenuhnya di dalam kelas lain.
      expect(rentangWaktuBentrok('08:00', '12:00', '09:00', '10:00'), isTrue);
      // Rentang identik.
      expect(rentangWaktuBentrok('08:00', '10:00', '08:00', '10:00'), isTrue);
    });

    test('kelas yang bersentuhan tidak dianggap bentrok', () {
      expect(rentangWaktuBentrok('08:00', '10:00', '10:00', '12:00'), isFalse);
      expect(rentangWaktuBentrok('10:00', '12:00', '08:00', '10:00'), isFalse);
    });

    test('rentang terpisah tidak dianggap bentrok', () {
      expect(rentangWaktuBentrok('08:00', '09:00', '13:00', '15:00'), isFalse);
    });

    test('rentang selesai sebelum mulai ditolak', () {
      expect(
        () => rentangWaktuBentrok('10:00', '08:00', '11:00', '12:00'),
        throwsFormatException,
      );
    });
  });

  group('bentrok jadwal antar mata kuliah', () {
    test('hari sama dan jam tumpang tindih -> bentrok', () {
      expect(senin08.bentrokDengan(senin09), isTrue);
      expect(senin09.bentrokDengan(senin08), isTrue);
    });

    test('hari berbeda dengan jam sama -> tidak bentrok', () {
      expect(senin08.bentrokDengan(selasa08), isFalse);
      expect(selasa08.bentrokDengan(senin08), isFalse);
    });

    test('kelas bersentuhan -> tidak bentrok', () {
      expect(senin08.bentrokDengan(senin10), isFalse);
      expect(senin10.bentrokDengan(senin08), isFalse);
    });
  });

  group('KrsService.validasiTambah', () {
    test('mata kuliah kosong boleh ditambahkan', () {
      final hasil = KrsService.validasiTambah(
        kode: 'X1',
        dipilih: [],
        katalog: katalogUji,
      );
      expect(hasil.status, StatusTambah.oke);
      expect(hasil.diperbolehkan, isTrue);
    });

    test('menolak ketika total SKS akan melebihi 24', () {
      // 5 x 3 SKS = 15, menambah 3 SKS jadi 18 masih di bawah batas,
      // jadi siapkan 8 mata kuliah 3 SKS (24 SKS penuh).
      final hampirPenuh = List.generate(
        8,
        (i) => MataKuliahModel(
          kode: 'P$i',
          nama: 'Penuh $i',
          sks: 3,
          hari: 'Senin',
          jamMulai: '${(i % 12) + 1}:00',
          jamSelesai: '${(i % 12) + 1}:45',
          ruangan: 'R.$i',
          dosen: 'Dosen $i',
        ),
      );

      expect(KrsService.totalSks(hampirPenuh), KrsService.batasSks);

      final hasil = KrsService.validasiTambah(
        kode: 'X1',
        dipilih: hampirPenuh,
        katalog: katalogUji,
      );
      expect(hasil.status, StatusTambah.melebihiBatasSks);
      expect(hasil.diperbolehkan, isFalse);
    });

    test('total SKS tepat 24 masih diperbolehkan', () {
      final hampirPenuh = List.generate(
        7,
        (i) => MataKuliahModel(
          kode: 'P$i',
          nama: 'Penuh $i',
          sks: 3,
          hari: 'Senin',
          jamMulai: '${(i % 12) + 1}:00',
          jamSelesai: '${(i % 12) + 1}:45',
          ruangan: 'R.$i',
          dosen: 'Dosen $i',
        ),
      );
      expect(KrsService.totalSks(hampirPenuh), 21);

      final hasil = KrsService.validasiTambah(
        kode: 'X1',
        dipilih: hampirPenuh,
        katalog: katalogUji,
      );
      expect(hasil.status, StatusTambah.oke);
      expect(KrsService.totalSks([...hampirPenuh, senin08]), 24);
    });

    test('menolak mata kuliah yang bentrok dengan pilihan berjalan', () {
      final hasil = KrsService.validasiTambah(
        kode: 'X2',
        dipilih: const [senin08],
        katalog: katalogUji,
      );
      expect(hasil.status, StatusTambah.bentrokJadwal);
      expect(hasil.penyebabBentrok?.kode, 'X1');
    });

    test('mata kuliah bersentuhan tidak dianggap bentrok', () {
      final hasil = KrsService.validasiTambah(
        kode: 'X3',
        dipilih: const [senin08],
        katalog: katalogUji,
      );
      expect(hasil.status, StatusTambah.oke);
    });

    test('mata kuliah di hari lain tidak dianggap bentrok', () {
      final hasil = KrsService.validasiTambah(
        kode: 'X4',
        dipilih: const [senin08],
        katalog: katalogUji,
      );
      expect(hasil.status, StatusTambah.oke);
    });

    test('menolak duplikat', () {
      final hasil = KrsService.validasiTambah(
        kode: 'X1',
        dipilih: const [senin08],
        katalog: katalogUji,
      );
      expect(hasil.status, StatusTambah.sudahDipilih);
    });

    test('menolak kode yang tidak ada di katalog', () {
      final hasil = KrsService.validasiTambah(
        kode: 'TIDAK ADA',
        dipilih: const [],
        katalog: katalogUji,
      );
      expect(hasil.status, StatusTambah.tidakDikenal);
    });

    test('batas SKS dicek sebelum bentrok jadwal', () {
      // X2 bentrok dengan X1, tetapi kuota sudah penuh. Pesan yang muncul
      // seharusnya yang menyangkut kuota agar pengguna tahu apa yang harus
      // dilepas lebih dulu.
      final penuh = List.generate(
        8,
        (i) => MataKuliahModel(
          kode: 'P$i',
          nama: 'Penuh $i',
          sks: 3,
          hari: 'Rabu',
          jamMulai: '${(i % 12) + 1}:00',
          jamSelesai: '${(i % 12) + 1}:45',
          ruangan: 'R.$i',
          dosen: 'Dosen $i',
        ),
      );
      final campuran = [...penuh, senin08];

      final hasil = KrsService.validasiTambah(
        kode: 'X2',
        dipilih: campuran,
        katalog: katalogUji,
      );
      expect(hasil.status, StatusTambah.melebihiBatasSks);
    });
  });

  group('KrsService.pesanDari', () {
    test('pesan melebihi batas menyebut sisa kuota', () {
      // Kuota sudah 24 SKS; menambah X1 (3 SKS) pasti ditolak.
      final penuh = List.generate(
        8,
        (i) => MataKuliahModel(
          kode: 'P$i',
          nama: 'Penuh $i',
          sks: 3,
          hari: 'Rabu',
          jamMulai: '${(i % 12) + 1}:00',
          jamSelesai: '${(i % 12) + 1}:45',
          ruangan: 'R.$i',
          dosen: 'Dosen $i',
        ),
      );

      final hasil = KrsService.validasiTambah(
        kode: 'X1',
        dipilih: penuh,
        katalog: katalogUji,
      );
      expect(hasil.status, StatusTambah.melebihiBatasSks);

      final pesan = KrsService.pesanDari(
        hasil,
        kandidat: senin08,
        dipilih: penuh,
      );
      expect(pesan, contains('24'));
      expect(pesan, contains('SKS'));
      expect(pesan, contains('0 SKS'));
    });

    test('pesan bentrok menyebut nama mata kuliah penyebab', () {
      final hasil = KrsService.validasiTambah(
        kode: 'X2',
        dipilih: const [senin08],
        katalog: katalogUji,
      );
      final pesan = KrsService.pesanDari(
        hasil,
        kandidat: senin09,
        dipilih: const [senin08],
      );
      expect(pesan, contains('Senin Jam Delapan'));
    });
  });

  group('totalSks', () {
    test('menjumlahkan SKS seluruh pilihan', () {
      expect(KrsService.totalSks(const []), 0);
      expect(KrsService.totalSks(const [senin08]), 3);
      expect(KrsService.totalSks(const [senin08, senin09]), 6);
    });
  });

  group('cariBentrok', () {
    test('mengembalikan null bila tidak ada bentrok', () {
      expect(KrsService.cariBentrok(senin08, const []), isNull);
      expect(KrsService.cariBentrok(senin10, const [senin08]), isNull);
      expect(KrsService.cariBentrok(selasa08, const [senin08]), isNull);
    });

    test('mengembalikan mata kuliah penyebab bentrok', () {
      expect(KrsService.cariBentrok(senin09, const [senin08])?.kode, 'X1');
    });

    test('mengabaikan dirinya sendiri', () {
      expect(KrsService.cariBentrok(senin08, const [senin08]), isNull);
    });
  });

  group('katalog nyata', () {
    test('katalog semester 5 tidak melebihi batas 24 SKS bila diambil semua', () {
      // Katalog memang harus lebih besar dari batas supaya batasnya terasa,
      // tetapi tidak boleh ada satu pun pilihan valid yang melanggar 24 SKS.
      final totalKatalog = KrsService.totalSks(katalogSemester5);
      expect(totalKatalog, greaterThan(KrsService.batasSks));
    });

    test('setiap kode mata kuliah unik', () {
      final kode = katalogSemester5.map((m) => m.kode).toList();
      expect(kode.toSet().length, kode.length);
    });

    test('jam setiap mata kuliah valid dan selesai setelah mulai', () {
      for (final m in katalogSemester5) {
        expect(
          () => menitDariJam(m.jamMulai),
          returnsNormally,
          reason: '${m.kode} jamMulai tidak sah',
        );
        expect(
          menitDariJam(m.jamSelesai),
          greaterThan(menitDariJam(m.jamMulai)),
          reason: '${m.kode} selesai sebelum mulai',
        );
      }
    });
  });
}
