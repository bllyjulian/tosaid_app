import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'daftar_bab.dart'; // Import halaman tujuan

class HalamanPengantarKategoriPage extends StatelessWidget {
  final String title; // Judul Halaman (misal: "Pengantar Istima'")
  final String pathPdf; // File PDF Pengantar

  // Data untuk halaman selanjutnya (Daftar Bab)
  final String titleDaftarBab; // Judul halaman selanjutnya
  final Color colorDaftarBab; // Warna tema
  final String kategoriDatabase; // Filter database
  final String kodeKategoriFile; // Kode file audio
  final List<Map<String, dynamic>> dataBab; // Data list materi

  const HalamanPengantarKategoriPage({
    super.key,
    required this.title,
    required this.pathPdf,
    required this.titleDaftarBab,
    required this.colorDaftarBab,
    required this.kategoriDatabase,
    required this.kodeKategoriFile,
    required this.dataBab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Info Box
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                    child: Text("Baca pengantar materi ini terlebih dahulu.",
                        style: TextStyle(fontSize: 12))),
              ],
            ),
          ),

          // PDF Viewer
          Expanded(
            child: SfPdfViewer.asset(
              pathPdf,
              enableDoubleTapZooming: true,
              onDocumentLoadFailed: (details) =>
                  print("Error: ${details.error}"),
            ),
          ),

          // Tombol Lanjut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: const Offset(0, -2))
            ]),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Saat klik lanjut, kirim semua data ke DaftarBabPage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DaftarBabPage(
                        title: titleDaftarBab,
                        color: colorDaftarBab,
                        kategoriDatabase: kategoriDatabase,
                        kodeKategoriFile: kodeKategoriFile,
                        dataBab: dataBab,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("LANJUT KE DAFTAR POLA",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
