import 'package:flutter/material.dart';
import 'halaman_materi.dart';
import 'halaman_kuis.dart';
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

      // ============================================================
      // BAGIAN TOMBOL BAWAH (KHUSUS QIRA'AH)
      // ============================================================
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
                  // KHUSUS QIRA'AH: LANGSUNG KE KUIS (Tanpa Dialog)
                  // Kita paksa ambil soal "Pola 1" karena Pola lain kosong
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanKuisPage(
                        title: "Latihan Qira'ah",
                        kategoriFilter: "Qira'ah",
                        polaFilter: "Pola 1", // <--- KITA PAKSA POLA 1
                        instruksi:
                            "langsung", // <--- Kode rahasia agar dialog tidak muncul
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          : null,

      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: dataBab.length,
        itemBuilder: (context, index) {
          // Cek Tarakib Pola 3 (Index ke-2)
          bool isTarakibPola3 = (kategoriDatabase == "Tarakib" && index == 2);

          // 1. LOGIKA MENYEMBUNYIKAN TOMBOL KECIL (DI LIST)
          // Sembunyikan tombol kecil JIKA:
          // - Tarakib Pola 3 (karena latihannya ada di dalam materi)
          // - ATAU Qira'ah (karena tombolnya SUDAH ADA DI BAWAH LAYAR)
          bool hideTombolLatihanDiSini = isTarakibPola3 || isQiraah;

          // 2. LOGIKA TOMBOL DI HALAMAN DALAM (DAFTAR MATERI)
          // Tampilkan tombol per-materi JIKA:
          // - BUKAN Qira'ah. (Qira'ah bersih dari tombol latihan di dalam materi)
          // - Tarakib Pola 3 akan jadi TRUE di sini, makanya nanti muncul di dalam.
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

                                // Kirim logika tombol dalam ke halaman materi
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
                          elevation: 0,
                        ),
                      ),
                    ),

                    // TOMBOL KERJAKAN LATIHAN (KECIL)
                    // Hanya muncul jika tidak disembunyikan oleh logika di atas
                    if (!hideTombolLatihanDiSini) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            String polaDB = "Pola ${index + 1}";
                            String kodePolFile = "pola${index + 1}";

                            // --- LOGIKA PEMBAGIAN NAVIGASI ---

                            // KASUS 1: ISTIMA' (Butuh Audio Pengantar Dulu)
                            if (kategoriDatabase == "Istima'") {
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
                            }
                            // KASUS 2: TARAKIB (Langsung Kuis + Dialog Instruksi)
                            else if (kategoriDatabase == "Tarakib") {
                              // Ambil teks instruksi dari dataBab di main.dart
                              // Kita ambil dari sub-bab pertama sebagai perwakilan
                              String teksInstruksi = "";
                              try {
                                // Ambil instruksi dari materi pertama di pola ini
                                teksInstruksi = dataBab[index]['sub_bab'][0]
                                        ['instruksi'] ??
                                    "";
                              } catch (e) {
                                teksInstruksi = "Kerjakan soal dengan teliti.";
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HalamanKuisPage(
                                    title: "Latihan $polaDB",
                                    kategoriFilter: kategoriDatabase,
                                    polaFilter: polaDB,

                                    // Kirim teks instruksi Arab ke halaman kuis
                                    instruksi: teksInstruksi,
                                  ),
                                ),
                              );
                            }
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
