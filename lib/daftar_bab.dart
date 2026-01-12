import 'package:flutter/material.dart';
import 'halaman_materi.dart';
import 'halaman_kuis.dart';
import 'halaman_pengantar.dart'; // Pastikan file ini ada (Audio Player)

class DaftarBabPage extends StatelessWidget {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> dataBab;

  // Parameter wajib untuk filter database & file
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
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: dataBab.length,
        itemBuilder: (context, index) {
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
                    // TOMBOL MATERI
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DaftarMateriPage(
                                title: "Materi Bab ${index + 1}",
                                dataMateri: dataBab[index]['sub_bab'] ?? [],
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
                    const SizedBox(width: 10),
                    // TOMBOL LATIHAN
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Kirim parameter ke Halaman Pengantar Audio (Latihan)
                          String polaDB = "Pola ${index + 1}";
                          String kodePolFile = "pola${index + 1}";

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HalamanPengantarPage(
                                title: "Latihan $polaDB",
                                kategoriFilter:
                                    kategoriDatabase, // Dari parameter class
                                polaFilter: polaDB,
                                kodeKategori:
                                    kodeKategoriFile, // Dari parameter class
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
