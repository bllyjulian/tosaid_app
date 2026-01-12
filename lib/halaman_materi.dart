import 'package:flutter/material.dart';
import 'halaman_baca_pdf.dart'; // Pastikan file ini sudah ada dan diimport

class DaftarMateriPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> dataMateri;

  const DaftarMateriPage({
    super.key,
    required this.title,
    required this.dataMateri,
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
          // Header Progress Bar
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
                return GestureDetector(
                  onTap: () {
                    // Ambil path dari data main.dart
                    String pathPdf = materi['file_pdf'] ?? "";
                    String judul = materi['judul_latin'] ?? "Materi";

                    if (pathPdf.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HalamanBacaPdf(
                            judul: judul,
                            pathPdf:
                                pathPdf, // Dia akan baca: assets/pdfs/1_pola1_materi1.pdf
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Materi belum tersedia")));
                    }
                  },
                  child: Container(
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
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Nomor Urut
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${index + 1}".padLeft(2, '0'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Teks Judul & Sub-judul
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                materi['judul_arab'] ?? "Judul Materi",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                materi['judul_latin'] ?? "Deskripsi Singkat",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Icon Panah (Diganti icon PDF biar lebih jelas)
                        const Icon(Icons.picture_as_pdf,
                            size: 20, color: Colors.redAccent),
                      ],
                    ),
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
