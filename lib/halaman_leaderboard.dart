import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HalamanLeaderboardPage extends StatefulWidget {
  const HalamanLeaderboardPage({super.key});

  @override
  State<HalamanLeaderboardPage> createState() => _HalamanLeaderboardPageState();
}

class _HalamanLeaderboardPageState extends State<HalamanLeaderboardPage> {
  List<Map<String, dynamic>> _topThree = [];
  List<Map<String, dynamic>> _otherRanks = [];
  Map<String, dynamic>? _myRankData; // Data ranking saya sendiri
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final supabase = Supabase.instance.client;
      final myUserId = supabase.auth.currentUser?.id;

      // 1. AMBIL DATA DARI "VIEW" YANG KITA BUAT TADI
      // View ini sudah otomatis mengurutkan skor tertinggi
      final response = await supabase
          .from('view_leaderboard')
          .select()
          .limit(50); // Ambil Top 50 saja

      List<Map<String, dynamic>> rawData =
          List<Map<String, dynamic>>.from(response);
      List<Map<String, dynamic>> processedList = [];

      // 2. Olah Data (Kasih Nomor Ranking & Warna)
      for (int i = 0; i < rawData.length; i++) {
        var item = rawData[i];
        int rank = i + 1;

        // Tentukan warna podium
        Color rankColor = Colors.grey;
        if (rank == 1)
          rankColor = const Color(0xFFFFD700); // Emas
        else if (rank == 2)
          rankColor = const Color(0xFFC0C0C0); // Perak
        else if (rank == 3) rankColor = const Color(0xFFCD7F32); // Perunggu

        Map<String, dynamic> userMap = {
          'user_id': item['user_id'],
          'nama': item['nama'] ?? 'Tanpa Nama',
          'skor': item['skor_tertinggi'] ?? 0,
          'rank': rank,
          'color': rankColor
        };

        processedList.add(userMap);

        // Cek apakah ini saya?
        if (item['user_id'] == myUserId) {
          _myRankData = userMap;
        }
      }

      // 3. Pisahkan Top 3 dan Sisanya
      if (processedList.length >= 3) {
        // Urutan Array Podium Visual: Kiri(Juara2), Tengah(Juara1), Kanan(Juara3)
        // Data sorted: [0]=Juara1, [1]=Juara2, [2]=Juara3
        _topThree = [
          processedList[1], // Posisi Kiri (Juara 2)
          processedList[0], // Posisi Tengah (Juara 1)
          processedList[2] // Posisi Kanan (Juara 3)
        ];
        _otherRanks = processedList.sublist(3);
      } else {
        // Fallback jika data kurang dari 3
        _topThree = processedList;
        _otherRanks = [];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error leaderboard: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Papan Peringkat TOSA",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 1. BAGIAN PODIUM (TOP 3)
          if (_topThree.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5))
                  ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _topThree.map((item) {
                  // Ukuran avatar: Juara 1 lebih besar
                  double size = item['rank'] == 1 ? 120 : 90;
                  return _buildPodiumItem(item, size);
                }).toList(),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Belum ada data peringkat."),
            ),

          const SizedBox(height: 20),

          // 2. DAFTAR RANKING (4 KE BAWAH)
          Expanded(
            child: _otherRanks.isEmpty && _topThree.isNotEmpty
                ? const Center(child: Text("Belum ada ranking lainnya."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _otherRanks.length,
                    itemBuilder: (context, index) {
                      final item = _otherRanks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            // Nomor Rank
                            SizedBox(
                              width: 30,
                              child: Text("${item['rank']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey)),
                            ),
                            const SizedBox(width: 10),
                            // Avatar Kecil (Initial Nama)
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue.shade50,
                              child: Text(item['nama'][0].toUpperCase(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800)),
                            ),
                            const SizedBox(width: 12),
                            // Nama & Skor
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nama'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  Text("Skor Tertinggi: ${item['skor']}",
                                      style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 3. BAR "POSISI SAYA" (Fixed di Bawah)
      bottomNavigationBar: _myRankData != null
          ? Container(
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
                  Text("${_myRankData!['rank']}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue,
                    child: Text(_myRankData!['nama'][0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${_myRankData!['nama']} (Saya)",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Skor Tertinggi: ${_myRankData!['skor']}",
                            style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox
              .shrink(), // Jika user belum pernah tes, sembunyikan bar bawah
    );
  }

  // WIDGET HELPER: MEMBUAT PODIUM
  Widget _buildPodiumItem(Map<String, dynamic> data, double size) {
    bool isJuara1 = data['rank'] == 1;

    return Column(
      children: [
        if (isJuara1)
          const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.workspace_premium,
                  color: Color(0xFFFFD700), size: 32)),

        // Avatar Lingkaran
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
            radius: isJuara1 ? 40 : 30,
            backgroundColor: Colors.grey[100],
            child: Text(data['nama'][0].toUpperCase(),
                style: TextStyle(
                    fontSize: isJuara1 ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ),
        ),
        const SizedBox(height: 8),

        // Nama
        Text(
          data['nama'].split(" ")[0], // Ambil nama depan saja
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),

        const SizedBox(height: 4),

        // Badge Rank
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: data['color'], borderRadius: BorderRadius.circular(12)),
          child: Text("${data['rank']}",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),

        const SizedBox(height: 4),
        Text("${data['skor']}",
            style: const TextStyle(
                color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
