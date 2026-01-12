import 'package:flutter/material.dart';
import 'dart:async';

class HalamanSimulasiPage extends StatefulWidget {
  const HalamanSimulasiPage({super.key});

  @override
  State<HalamanSimulasiPage> createState() => _HalamanSimulasiPageState();
}

class _HalamanSimulasiPageState extends State<HalamanSimulasiPage> {
  // --- KONFIGURASI WAKTU ---
  static const int durasiPerSection = 1 * 65; // 20 Menit

  // --- STATE VARIABEL ---
  int currentSectionIndex = 0;
  int currentSoalIndex = 0;
  int sisaWaktu = durasiPerSection;
  Timer? _timer;
  int totalSkor = 0;

  // VARIABLE BARU: UNTUK MENYIMPAN RIWAYAT JAWABAN
  List<Map<String, dynamic>> laporanHasil = [];

  // --- DATA SOAL ---
  final List<Map<String, dynamic>> dataSections = [
    {
      'nama': "Section 1: Istima' (Menyimak)",
      'warna': const Color(0xFF42A5F5),
      'soal': [
        {
          'tanya': 'Dengarkan audio. Apa profesi Ahmad?',
          'opsi': ['Guru', 'Dokter', 'Insinyur', 'Pedagang'],
          'kunci': 0 // Guru
        },
        {
          'tanya': 'Dimana percakapan ini terjadi?',
          'opsi': ['Pasar', 'Kampus', 'Rumah Sakit', 'Bandara'],
          'kunci': 1 // Kampus
        },
      ]
    },
    {
      'nama': "Section 2: Qira'ah (Membaca)",
      'warna': const Color(0xFFFF9800),
      'soal': [
        {
          'tanya': 'Apa gagasan utama paragraf pertama?',
          'opsi': ['Pendidikan', 'Ekonomi', 'Sejarah', 'Budaya'],
          'kunci': 2 // Sejarah
        },
        {
          'tanya': 'Kata "Al-Madrasah" artinya...',
          'opsi': ['Kantor', 'Sekolah', 'Rumah', 'Toko'],
          'kunci': 1 // Sekolah
        },
      ]
    },
    {
      'nama': "Section 3: Tarakib (Struktur)",
      'warna': const Color(0xFF9C27B0),
      'soal': [
        {
          'tanya': 'Lengkapi: Ana ... ilal madrasah.',
          'opsi': ['Adzhabu', 'Yadzhabu', 'Tadzhabu', 'Nadzhabu'],
          'kunci': 0 // Adzhabu
        },
        {
          'tanya': 'Bentuk jamak dari "Kitabun" adalah...',
          'opsi': ['Kitabani', 'Kutubun', 'Makatib', 'Katibun'],
          'kunci': 1 // Kutubun
        },
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sisaWaktu > 0) {
        setState(() {
          sisaWaktu--;
        });
      } else {
        _timer?.cancel();
        pindahSectionOtomatis();
      }
    });
  }

  void pindahSectionOtomatis() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title:
            const Text("Waktu Habis! ⏰", style: TextStyle(color: Colors.red)),
        content: Text(
            "Waktu untuk ${dataSections[currentSectionIndex]['nama']} telah selesai. Lanjut ke bagian berikutnya."),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              lanjutKeNextSection();
            },
            child: const Text("Lanjut"),
          )
        ],
      ),
    );
  }

  void lanjutKeNextSection() {
    if (currentSectionIndex < dataSections.length - 1) {
      setState(() {
        currentSectionIndex++;
        currentSoalIndex = 0;
        sisaWaktu = durasiPerSection;
      });
      startTimer();
    } else {
      selesaiTes();
    }
  }

  // --- FUNGSI JAWAB SOAL YANG DIPERBARUI ---
  void jawabSoal(int indexOpsi) {
    // Ambil Data Soal Saat Ini
    var sectionSaatIni = dataSections[currentSectionIndex];
    var soalSaatIni = sectionSaatIni['soal'][currentSoalIndex];

    // Cek Benar/Salah
    int kunci = soalSaatIni['kunci'];
    bool isBenar = (indexOpsi == kunci);

    // Hitung Skor
    if (isBenar) {
      totalSkor += 10;
    }

    // --- REKAM JEJAK JAWABAN (LOGGING) ---
    laporanHasil.add({
      'section': sectionSaatIni['nama'], // Nama Section
      'pertanyaan': soalSaatIni['tanya'], // Soalnya apa
      'jawaban_user': soalSaatIni['opsi'][indexOpsi], // User jawab apa
      'jawaban_benar': soalSaatIni['opsi'][kunci], // Kunci jawabannya apa
      'status': isBenar, // True kalau benar, False kalau salah
    });

    // Pindah Soal / Section
    List soalList = sectionSaatIni['soal'];
    if (currentSoalIndex < soalList.length - 1) {
      setState(() {
        currentSoalIndex++;
      });
    } else {
      // Jika soal habis di section ini
      _timer?.cancel();

      // Cek apakah ini section terakhir?
      if (currentSectionIndex == dataSections.length - 1) {
        selesaiTes(); // Selesai semua
      } else {
        _tampilKonfirmasiSelesaiSection(); // Lanjut ke section berikutnya
      }
    }
  }

  void _tampilKonfirmasiSelesaiSection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bagian Selesai"),
        content: const Text("Lanjut ke bagian berikutnya?"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              lanjutKeNextSection();
            },
            child: const Text("Lanjut"),
          ),
        ],
      ),
    );
  }

  void selesaiTes() {
    // Navigasi ke Halaman Hasil membawa Data Skor DAN Data Laporan
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HasilSimulasiPage(
          skorAkhir: totalSkor,
          laporan: laporanHasil, // KITA KIRIM DATA LAPORANNYA DI SINI
        ),
      ),
    );
  }

  String get formatWaktu {
    int menit = sisaWaktu ~/ 60;
    int detik = sisaWaktu % 60;
    return "${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final sectionData = dataSections[currentSectionIndex];
    final List soalList = sectionData['soal'];
    final soalCurrent = soalList[currentSoalIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Simulasi TOSA",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sisaWaktu < 60 ? Colors.red[100] : Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(formatWaktu,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sectionData['warna'],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(sectionData['nama'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("Soal ${currentSoalIndex + 1} / ${soalList.length}",
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(soalCurrent['tanya'],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ...List.generate(soalCurrent['opsi'].length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => jawabSoal(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(soalCurrent['opsi'][index],
                      style: const TextStyle(fontSize: 16)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// --- CLASS BARU UNTUK HASIL & PEMBAHASAN ---

class HasilSimulasiPage extends StatelessWidget {
  final int skorAkhir;
  // Menerima data laporan
  final List<Map<String, dynamic>> laporan;

  const HasilSimulasiPage({
    super.key,
    required this.skorAkhir,
    required this.laporan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/peringkat.png', width: 120),
              const SizedBox(height: 24),
              const Text("Simulasi Selesai!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Estimasi Skor TOSA Anda:",
                  style: TextStyle(color: Colors.grey)),
              Text("$skorAkhir",
                  style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),

              const SizedBox(height: 40),

              // TOMBOL LIHAT PEMBAHASAN (BARU)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Buka Halaman Pembahasan
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HalamanPembahasanPage(laporan: laporan),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text("Lihat Pembahasan"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // TOMBOL KEMBALI
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Kembali ke Dashboard",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HalamanPembahasanPage extends StatelessWidget {
  final List<Map<String, dynamic>> laporan;

  const HalamanPembahasanPage({super.key, required this.laporan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembahasan Soal",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: laporan.isEmpty
          ? const Center(child: Text("Belum ada data jawaban."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: laporan.length,
              itemBuilder: (context, index) {
                final item = laporan[index];
                final bool isBenar = item['status'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  // PERBAIKAN ADA DI SINI:
                  // 'side' kita masukkan ke dalam RoundedRectangleBorder
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isBenar ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label Section (Kecil di atas)
                        Text(item['section'],
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        // Pertanyaan
                        Text(item['pertanyaan'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Jawaban Kamu
                        Row(
                          children: [
                            Icon(isBenar ? Icons.check_circle : Icons.cancel,
                                color: isBenar ? Colors.green : Colors.red,
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(TextSpan(children: [
                                const TextSpan(
                                    text: "Jawaban Kamu: ",
                                    style: TextStyle(color: Colors.grey)),
                                TextSpan(
                                    text: item['jawaban_user'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isBenar
                                            ? Colors.green
                                            : Colors.red)),
                              ])),
                            ),
                          ],
                        ),

                        // Kunci Jawaban (Hanya muncul jika salah)
                        if (!isBenar) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.key,
                                  color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(TextSpan(children: [
                                  const TextSpan(
                                      text: "Kunci Jawaban: ",
                                      style: TextStyle(color: Colors.grey)),
                                  TextSpan(
                                      text: item['jawaban_benar'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green)),
                                ])),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
