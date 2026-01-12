import 'package:flutter/material.dart';

class HalamanRaporPage extends StatelessWidget {
  const HalamanRaporPage({super.key});

  @override
  Widget build(BuildContext context) {
    // --- DATA DUMMY NILAI ---
    final List<Map<String, dynamic>> riwayatNilai = [
      {
        'mapel': "Istima' (Menyimak)",
        'bab': "Bab 1: Perkenalan",
        'nilai': 100,
        'tanggal': '25 Okt 2025',
        'status': 'Sempurna'
      },
      {
        'mapel': "Qira'ah (Membaca)",
        'bab': "Bab 1: Teks Pendek",
        'nilai': 80,
        'tanggal': '24 Okt 2025',
        'status': 'Lulus'
      },
      {
        'mapel': "Tarakib (Struktur)",
        'bab': "Bab 1: Kalimat Dasar",
        'nilai': 40,
        'tanggal': '23 Okt 2025',
        'status': 'Remidi'
      },
      {
        'mapel': "Simulasi TOSA",
        'bab': "Try Out 1",
        'nilai': 450, // Skor TOSA biasanya ratusan
        'tanggal': '22 Okt 2025',
        'status': 'Cukup'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Riwayat Belajar",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Hilangkan tombol back karena ini menu utama
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU RINGKASAN (Header Biru)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF009688), Color(0xFF4DB6AC)], // Warna Tosca
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Statistik 1
                  Column(
                    children: const [
                      Text("Rata-rata",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(height: 5),
                      Text("85",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(height: 40, width: 1, color: Colors.white24),
                  // Statistik 2
                  Column(
                    children: const [
                      Text("Total Kuis",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(height: 5),
                      Text("4",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(height: 40, width: 1, color: Colors.white24),
                  // Statistik 3
                  Column(
                    children: const [
                      Text("Predikat",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(height: 5),
                      Text("B",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text("Detail Nilai",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // 2. LIST RIWAYAT NILAI
            ...riwayatNilai.map((data) {
              return _buildNilaiCard(data);
            }).toList(),
          ],
        ),
      ),
    );
  }

  // WIDGET KARTU NILAI
  Widget _buildNilaiCard(Map<String, dynamic> data) {
    // Tentukan warna berdasarkan nilai
    Color warnaBadge;
    if (data['mapel'] == "Simulasi TOSA") {
      warnaBadge = Colors.blue; // Khusus TOSA warnanya biru
    } else if (data['nilai'] >= 80) {
      warnaBadge = Colors.green;
    } else if (data['nilai'] >= 60) {
      warnaBadge = Colors.orange;
    } else {
      warnaBadge = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Lingkaran Nilai
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: warnaBadge.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              "${data['nilai']}",
              style: TextStyle(
                  color: warnaBadge, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),

          // Info Mapel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['mapel'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(data['bab'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                // Tanggal & Status
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 10, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(data['tanggal'],
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 10)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: warnaBadge.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data['status'],
                        style: TextStyle(
                            color: warnaBadge,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),

          // Icon Panah
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[300]),
        ],
      ),
    );
  }
}
