import 'package:flutter/material.dart';

class HalamanLeaderboardPage extends StatelessWidget {
  const HalamanLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // --- DATA DUMMY LEADERBOARD ---
    final List<Map<String, dynamic>> topThree = [
      {
        'nama': 'Ahmad Zaky',
        'xp': 2400,
        'rank': 2,
        'color': Colors.grey
      }, // Silver
      {
        'nama': 'Siti Aminah',
        'xp': 3500,
        'rank': 1,
        'color': const Color(0xFFFFD700)
      }, // Gold
      {
        'nama': 'Budi Santoso',
        'xp': 1950,
        'rank': 3,
        'color': const Color(0xFFCD7F32)
      }, // Bronze
    ];

    final List<Map<String, dynamic>> otherRanks = [
      {'nama': 'Dewi Sartika', 'xp': 1800, 'rank': 4},
      {'nama': 'Rizky Billar', 'xp': 1750, 'rank': 5},
      {'nama': 'Putri Delina', 'xp': 1600, 'rank': 6},
      {'nama': 'Raffi Ahmad', 'xp': 1550, 'rank': 7},
      {'nama': 'Atta H.', 'xp': 1400, 'rank': 8},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Background agak abu
      appBar: AppBar(
        title: const Text("Papan Peringkat",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. BAGIAN PODIUM (TOP 3)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end, // Biar nempel bawah
              children: [
                // JUARA 2 (Kiri)
                _buildPodiumItem(topThree[0], 90),
                // JUARA 1 (Tengah - Lebih Besar)
                _buildPodiumItem(topThree[1], 120),
                // JUARA 3 (Kanan)
                _buildPodiumItem(topThree[2], 90),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. DAFTAR RANKING (4 KE BAWAH)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: otherRanks.length,
              itemBuilder: (context, index) {
                final item = otherRanks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Nomor Rank
                      Text(
                        "${item['rank']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      // Avatar Kecil
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue,
                        child:
                            Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Nama & XP
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nama'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("${item['xp']} XP",
                                style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      // Ikon Naik (Hiasan)
                      const Icon(Icons.arrow_drop_up, color: Colors.green),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // 3. BAR "POSISI SAYA" (Fixed di Bawah)
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            const Text("15",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)), // Rank Kita
            const SizedBox(width: 16),
            // Avatar Kita
            const CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(
                  'assets/images/profil.png'), // Pastikan gambar profil ada
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Witri (Saya)",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("1250 XP",
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Indikator Naik
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.keyboard_double_arrow_up, color: Colors.green),
                Text("Naik",
                    style: TextStyle(fontSize: 10, color: Colors.green)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // WIDGET HELPER: MEMBUAT PODIUM (Gambar Mahkota & Avatar)
  Widget _buildPodiumItem(Map<String, dynamic> data, double size) {
    bool isJuara1 = data['rank'] == 1;

    return Column(
      children: [
        // Mahkota (Cuma buat Juara 1)
        if (isJuara1)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Icon(Icons.workspace_premium,
                color: Color(0xFFFFD700), size: 32),
          ),

        // Avatar dengan Border Warna (Emas/Perak/Perunggu)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: data['color'], width: 3),
              boxShadow: [
                BoxShadow(
                    color: data['color'].withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2)
              ]),
          child: CircleAvatar(
            radius: isJuara1 ? 40 : 30, // Juara 1 lebih besar
            backgroundColor: Colors.grey[200],
            child: Text(
              data['nama'][0], // Ambil Huruf Depan Nama
              style: TextStyle(
                  fontSize: isJuara1 ? 24 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Nama
        Text(
          data['nama'].split(" ")[0], // Ambil nama depan aja biar muat
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),

        // Badge Rank (Bulat Kecil)
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: data['color'],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${data['rank']}",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),

        const SizedBox(height: 4),
        Text("${data['xp']} XP",
            style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }
}
