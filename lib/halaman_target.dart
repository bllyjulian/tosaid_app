import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class HalamanTargetPage extends StatefulWidget {
  const HalamanTargetPage({super.key});

  @override
  State<HalamanTargetPage> createState() => _HalamanTargetPageState();
}

class _HalamanTargetPageState extends State<HalamanTargetPage> {
  // Data Misi Harian (Dummy)
  List<Map<String, dynamic>> misiHarian = [
    {'judul': 'Login Aplikasi', 'xp': 10, 'selesai': true},
    {'judul': 'Selesaikan 1 Materi Istima\'', 'xp': 50, 'selesai': true},
    {'judul': 'Kerjakan Latihan Qira\'ah', 'xp': 30, 'selesai': false},
    {'judul': 'Dapat Nilai 100 di Kuis', 'xp': 100, 'selesai': false},
    {'judul': 'Belajar selama 30 Menit', 'xp': 20, 'selesai': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Target Belajar",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER STATISTIK (Warna Warni)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Kolom 1: Streak
                  Column(
                    children: const [
                      Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 32),
                      SizedBox(height: 8),
                      Text("7 Hari",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text("Streak",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  // Garis Pemisah
                  Container(height: 40, width: 1, color: Colors.white24),
                  // Kolom 2: Total XP
                  Column(
                    children: const [
                      Icon(Icons.star, color: Colors.yellow, size: 32),
                      SizedBox(height: 8),
                      Text("1250",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text("Total XP",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  // Garis Pemisah
                  Container(height: 40, width: 1, color: Colors.white24),
                  // Kolom 3: Jam Belajar
                  Column(
                    children: const [
                      Icon(Icons.timer, color: Colors.white, size: 32),
                      SizedBox(height: 8),
                      Text("2.5 Jam",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text("Total Waktu",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. KALENDER MINGGUAN (Checkmark)
            const Text("Aktivitas Minggu Ini",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _HariCircle(hari: "S", aktif: true),
                  _HariCircle(hari: "S", aktif: true),
                  _HariCircle(hari: "R", aktif: true),
                  _HariCircle(hari: "K", aktif: true),
                  _HariCircle(hari: "J", aktif: false), // Jumat bolong (misal)
                  _HariCircle(hari: "S", aktif: false),
                  _HariCircle(hari: "M", aktif: false),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. MISI HARIAN (Checklist)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Misi Harian",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Reset dalam 12:30:00",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),

            // Generate List Misi
            ...misiHarian.map((misi) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: misi['selesai']
                          ? Colors.green.withOpacity(0.5)
                          : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // Checkbox Custom
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          misi['selesai'] = !misi['selesai'];
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              misi['selesai'] ? Colors.green : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                                  misi['selesai'] ? Colors.green : Colors.grey),
                        ),
                        child: misi['selesai']
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Teks Judul
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            misi['judul'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              decoration: misi['selesai']
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: misi['selesai']
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                          Text("+${misi['xp']} XP",
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // Icon Hadiah (Peti Harta)
                    if (misi['selesai'])
                      const Icon(Icons.wallet_giftcard, color: Colors.orange),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// Widget Kecil untuk Lingkaran Hari (S, S, R, K...)
class _HariCircle extends StatelessWidget {
  final String hari;
  final bool aktif;

  const _HariCircle({required this.hari, required this.aktif});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: aktif ? Colors.blue : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Text(
            hari,
            style: TextStyle(
              color: aktif ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (aktif) const Icon(Icons.check, size: 12, color: Colors.green)
      ],
    );
  }
}
