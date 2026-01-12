import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class HalamanBacaPdf extends StatelessWidget {
  final String judul;
  final String pathPdf;

  const HalamanBacaPdf({super.key, required this.judul, required this.pathPdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(judul,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // DI ANDROID, CUKUP PAKAI INI. DIJAMIN JALAN!
      body: SfPdfViewer.asset(
        pathPdf,
        enableDoubleTapZooming: true,
      ),
    );
  }
}
