import 'package:flutter/material.dart';
import 'halaman_baca_pdf.dart';
import 'halaman_kuis.dart'; // Import Halaman Kuis Langsung (Tanpa Pengantar Audio)

class DaftarMateriPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> dataMateri;

  // Parameter Baru untuk Logika Tarakib Pola 3
  final bool showLatihanButton;
  final Map<String, String>? kategoriInfo;

  const DaftarMateriPage({
    super.key,
    required this.title,
    required this.dataMateri,
    this.showLatihanButton = false, // Default false (tidak muncul)
    this.kategoriInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Header Progress
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${dataMateri.length} Topik Tersedia",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: 0.0,
                    minHeight: 6,
                    backgroundColor: Color(0xFFEEEEEE),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF42A5F5)),
                  ),
                ),
              ],
            ),
          ),

          // List Materi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: dataMateri.length,
              itemBuilder: (context, index) {
                final materi = dataMateri[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Bagian Atas: Judul Materi & Icon PDF (Bisa diklik untuk baca)
                      InkWell(
                        onTap: () {
                          String pathPdf = materi['file_pdf'] ?? "";
                          String judul = materi['judul_latin'] ?? "Materi";
                          if (pathPdf.isNotEmpty) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HalamanBacaPdf(
                                        judul: judul, pathPdf: pathPdf)));
                          }
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text("${index + 1}".padLeft(2, '0'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(materi['judul_arab'] ?? "Judul Materi",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                      materi['judul_latin'] ??
                                          "Deskripsi Singkat",
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.picture_as_pdf,
                                size: 24, color: Colors.redAccent),
                          ],
                        ),
                      ),

                      // Bagian Bawah: Tombol Latihan (Hanya muncul jika showLatihanButton == true)
                      if (showLatihanButton) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // 1. Ambil Judul (Sekarang isinya Latin kan? misal "Mubtada Khabar")
                              String judulUntukFilter =
                                  materi['judul_arab'] ?? "";

                              // 2. [BARU] Ambil Instruksi dari main.dart
                              String? teksInstruksi = materi['instruksi'];

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HalamanKuisPage(
                                    title: "Latihan: $judulUntukFilter",

                                    // Data Kategori & Pola (Tetap)
                                    kategoriFilter: kategoriInfo!['kategori']!,
                                    polaFilter: kategoriInfo!['pola']!,

                                    // [PENTING 1] Filter Sub-Bab (Jangan dikomen, ini wajib biar soalnya spesifik)
                                    subBabFilter: judulUntukFilter,

                                    // [PENTING 2] Kirim Instruksi ke Kuis
                                    instruksi: teksInstruksi,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_note,
                                size: 16, color: Colors.white),
                            label: const Text("Latihan Sub-Bab Ini",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        )
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
