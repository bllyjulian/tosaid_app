import 'package:flutter/material.dart';
import 'halaman_materi.dart';
import 'halaman_kuis.dart'; // Pastikan import ini ada jika langsung ke kuis, atau pengantar
import 'halaman_pengantar.dart';

class DaftarBabPage extends StatelessWidget {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> dataBab;

  final String kategoriDatabase;
  final String kodeKategoriFile;

  const DaftarBabPage({
    super.key,
    required this.title,
    required this.color,
    required this.dataBab,
    required this.kategoriDatabase,
    required this.kodeKategoriFile,
  });

  @override
  Widget build(BuildContext context) {
    // Cek apakah ini menu Qira'ah
    bool isQiraah = kategoriDatabase == "Qira'ah";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // --- TOMBOL SATU UNTUK SEMUA (KHUSUS QIRA'AH) ---
      bottomNavigationBar: isQiraah
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Arahkan ke latihan gabungan / umum
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanPengantarPage(
                        title: "Latihan Qira'ah (Semua Pola)",
                        kategoriFilter: "Qira'ah",
                        // Gunakan filter khusus, misalnya "Semua" atau ambil pola 1 sebagai default
                        // Nanti di query database harus disesuaikan agar mengambil semua soal Qira'ah
                        polaFilter: "Semua",
                        kodeKategori: kodeKategoriFile,
                        kodePola: "all",
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                label: const Text("KERJAKAN LATIHAN (SEMUA POLA)",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, // Sesuaikan warna tema
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          : null, // Jika bukan Qira'ah, tidak ada tombol bawah
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: dataBab.length,
        itemBuilder: (context, index) {
          // --- LOGIKA PENGECEKAN ---
          bool isTarakibPola3 = (kategoriDatabase == "Tarakib" && index == 2);

          // Sembunyikan tombol latihan di list JIKA:
          // 1. Ini adalah Tarakib Pola 3 (karena format drag drop khusus/belum ada)
          // 2. ATAU Ini adalah Qira'ah (karena tombolnya sudah dipindah ke bawah)
          bool hideLatihanButton = isTarakibPola3 || isQiraah;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 6,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("POLA ${index + 1}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Text(dataBab[index]['judul'],
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // TOMBOL MATERI (Selalu Muncul)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DaftarMateriPage(
                                title: "Materi Bab ${index + 1}",
                                dataMateri: dataBab[index]['sub_bab'] ?? [],
                                showLatihanButton: !hideLatihanButton,
                                kategoriInfo: {
                                  'kategori': kategoriDatabase,
                                  'pola': "Pola ${index + 1}",
                                  'kode_kat': kodeKategoriFile,
                                  'kode_pol': "pola${index + 1}",
                                },
                              ),
                            ),
                          );
                        },
                        icon: Image.asset('assets/icons/materi.png',
                            width: 18, color: Colors.white),
                        label: const Text("Pelajari Materi",
                            style:
                                TextStyle(color: Colors.white, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF42A5F5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),

                    // TOMBOL LATIHAN (Hanya Muncul Jika TIDAK disembunyikan)
                    if (!hideLatihanButton) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            String polaDB = "Pola ${index + 1}";
                            String kodePolFile = "pola${index + 1}";

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HalamanPengantarPage(
                                  title: "Latihan $polaDB",
                                  kategoriFilter: kategoriDatabase,
                                  polaFilter: polaDB,
                                  kodeKategori: kodeKategoriFile,
                                  kodePola: kodePolFile,
                                ),
                              ),
                            );
                          },
                          icon: Image.asset('assets/icons/latihan.png',
                              width: 18, color: Colors.white),
                          label: const Text("Kerjakan Latihan",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ]
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
