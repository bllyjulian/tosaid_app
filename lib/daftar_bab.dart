import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import Animasi
import 'halaman_materi.dart';
import 'halaman_kuis.dart';
import 'halaman_pengantar.dart';
import 'halaman_evaluasi_istima.dart';
import 'halaman_evaluasi_qiraah.dart';

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
    // 1. Cek Kategori
    bool isQiraah = kategoriDatabase == "Qira'ah";
    bool isIstima = kategoriDatabase == "Istima'";

    // Evaluasi muncul di Qira'ah & Istima
    bool showEvaluasiAkhir = isIstima || isQiraah;

    // Warna Kartu Kuis
    List<Color> warnaEvaluasi = isQiraah
        ? [Colors.green.shade400, Colors.green.shade700]
        : [const Color(0xFFFF9800), const Color(0xFFF57C00)];

    // LOGIKA NAMA KUIS (REQ USER: Kuis Istima / Kuis Qiraah)
    String judulKuis = isIstima
        ? "Kuis Istima"
        : (isQiraah ? "Kuis Qiraah" : "Evaluasi Akhir");

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

      // TIDAK ADA BOTTOM NAVIGATION BAR (Tombol dipindah ke body)

      // ============================================================
      // BODY: LIST DENGAN URUTAN BAB -> TOMBOL LATIHAN -> KARTU KUIS
      // ============================================================
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. DAFTAR BAB (MATERI)
          ...dataBab.asMap().entries.map((entry) {
            int index = entry.key;
            var bab = entry.value;

            // Cek Tarakib Pola 3
            bool isTarakibPola3 = (kategoriDatabase == "Tarakib" && index == 2);

            // Logic Hide Tombol Kecil:
            // 1. Tarakib Pola 3 -> Hide
            // 2. Qira'ah -> Hide (Karena ada tombol besar di bawah list bab)
            bool hideTombolLatihanDiSini = isTarakibPola3 || isQiraah;
            bool showTombolLatihanDiDalam = !isQiraah;

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
                  Text(bab['judul'],
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // TOMBOL MATERI
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DaftarMateriPage(
                                  title: "Materi Bab ${index + 1}",
                                  dataMateri: bab['sub_bab'] ?? [],
                                  showLatihanButton: showTombolLatihanDiDalam,
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
                              elevation: 0),
                        ),
                      ),

                      // TOMBOL LATIHAN KECIL (Hide untuk Qira'ah)
                      if (!hideTombolLatihanDiSini) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              String polaDB = "Pola ${index + 1}";
                              String kodePolFile = "pola${index + 1}";

                              if (kategoriDatabase == "Istima'") {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            HalamanPengantarPage(
                                                title: "Latihan $polaDB",
                                                kategoriFilter:
                                                    kategoriDatabase,
                                                polaFilter: polaDB,
                                                kodeKategori: kodeKategoriFile,
                                                kodePola: kodePolFile)));
                              } else if (kategoriDatabase == "Tarakib") {
                                String teksInstruksi = "";
                                try {
                                  teksInstruksi =
                                      bab['sub_bab'][0]['instruksi'] ?? "";
                                } catch (e) {
                                  teksInstruksi =
                                      "Kerjakan soal dengan teliti.";
                                }
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => HalamanKuisPage(
                                            title: "Latihan $polaDB",
                                            kategoriFilter: kategoriDatabase,
                                            polaFilter: polaDB,
                                            instruksi: teksInstruksi)));
                              }
                            },
                            icon: Image.asset('assets/icons/latihan.png',
                                width: 18, color: Colors.white),
                            label: const Text("Kerjakan Latihan",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0),
                          ),
                        ),
                      ]
                    ],
                  )
                ],
              ),
            )
                .animate(delay: (100 * index).ms)
                .fadeIn(duration: 500.ms)
                .slideX(begin: 0.1, end: 0);
          }),

          // 2. TOMBOL LATIHAN QIRA'AH (KHUSUS QIRA'AH)
          // POSISI: DI ATAS KARTU KUIS
          if (isQiraah) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HalamanKuisPage(
                      title: "Latihan Qira'ah",
                      kategoriFilter: "Qira'ah",
                      polaFilter: "Pola 1",
                      instruksi: "langsung",
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
              label: const Text("KERJAKAN LATIHAN",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(double.infinity, 55),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                shadowColor: color.withOpacity(0.4),
              ),
            ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),
            const SizedBox(height: 30),
          ],

          // 3. KARTU KUIS / EVALUASI (PALING BAWAH)
          if (showEvaluasiAkhir)
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: warnaEvaluasi),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: warnaEvaluasi[0].withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars,
                              color: Colors.white, size: 30),
                          const SizedBox(width: 10),
                          // JUDUL SESUAI REQUEST (Kuis Istima / Qiraah)
                          Text(judulKuis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isIstima
                            ? "Uji kemampuan menyimakmu dengan Tebak Gambar & Audio!"
                            : "Uji pemahaman bacaan dan kosakata Qira'ah!",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isIstima) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const HalamanEvaluasiIstima()));
                            } else if (isQiraah) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const HalamanEvaluasiQiraah()));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: isQiraah
                                  ? Colors.green.shade800
                                  : Colors.orange,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: const Text("MULAI KUIS",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                )
                    // ANIMASI KARTU KUIS
                    .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true))
                    .shimmer(
                        duration: 2000.ms, color: Colors.white.withOpacity(0.3))
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 30),
              ],
            ),
        ],
      ),
    );
  }
}
