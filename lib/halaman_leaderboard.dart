import 'package:flutter/material.dart';
// 1. SEMBUNYIKAN User DARI SUPABASE BIAR GAK BENTROK
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
// 2. IMPORT FIREBASE AUTH
import 'package:firebase_auth/firebase_auth.dart';

class HalamanLeaderboardPage extends StatefulWidget {
  const HalamanLeaderboardPage({super.key});

  @override
  State<HalamanLeaderboardPage> createState() => _HalamanLeaderboardPageState();
}

class _HalamanLeaderboardPageState extends State<HalamanLeaderboardPage> {
  List<Map<String, dynamic>> _topThree = [];
  List<Map<String, dynamic>> _otherRanks = [];
  Map<String, dynamic>? _myRankData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  // --- FUNGSI PINTAR UNTUK AVATAR ---
  ImageProvider _getAvatarImage(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return NetworkImage(url); // Foto Internet
      } else {
        return AssetImage(url); // Foto Asset
      }
    }
    return const AssetImage('assets/images/profil.png');
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final supabase = Supabase.instance.client;

      // 3. AMBIL ID DARI FIREBASE (Karena login pake Firebase)
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final myUserId = firebaseUser?.uid;

      // Ambil data dari View Supabase
      final response =
          await supabase.from('view_leaderboard').select().limit(50);

      List<Map<String, dynamic>> rawData =
          List<Map<String, dynamic>>.from(response);
      List<Map<String, dynamic>> processedList = [];

      // Olah Data
      for (int i = 0; i < rawData.length; i++) {
        var item = rawData[i];
        int rank = i + 1;

        Color rankColor = Colors.grey;
        if (rank == 1)
          rankColor = const Color(0xFFFFD700);
        else if (rank == 2)
          rankColor = const Color(0xFFC0C0C0);
        else if (rank == 3) rankColor = const Color(0xFFCD7F32);

        Map<String, dynamic> userMap = {
          'user_id': item['user_id'],
          'nama': item['nama'] ?? 'Tanpa Nama',
          'skor': item['skor_tertinggi'] ?? 0,
          'avatar_url': item['avatar_url'],
          'rank': rank,
          'color': rankColor
        };

        processedList.add(userMap);

        // Cek ID Firebase == ID di Supabase (buat highlight "Saya")
        if (item['user_id'] == myUserId) {
          _myRankData = userMap;
        }
      }

      // Pisahkan Top 3
      if (processedList.length >= 3) {
        _topThree = [processedList[1], processedList[0], processedList[2]];
        _otherRanks = processedList.sublist(3);
      } else {
        _topThree = processedList;
        _otherRanks = [];
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print("Error leaderboard: $e");
      if (mounted) setState(() => _isLoading = false);
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
          // BAGIAN PODIUM (TOP 3)
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

          // LIST RANKING SISANYA
          Expanded(
            child: _otherRanks.isEmpty && _topThree.isNotEmpty
                ? const Center(child: Text("Belum ada ranking lainnya."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _otherRanks.length,
                    itemBuilder: (context, index) {
                      final item = _otherRanks[index];
                      bool hasAvatar = item['avatar_url'] != null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text("${item['rank']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey)),
                            ),
                            const SizedBox(width: 10),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue.shade50,
                              backgroundImage: hasAvatar
                                  ? _getAvatarImage(item['avatar_url'])
                                  : null,
                              child: !hasAvatar
                                  ? Text(item['nama'][0].toUpperCase(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800))
                                  : null,
                            ),
                            const SizedBox(width: 12),
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

      // BAR POSISI SAYA (BOTTOM)
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
                    backgroundImage: _myRankData!['avatar_url'] != null
                        ? _getAvatarImage(_myRankData!['avatar_url'])
                        : null,
                    child: _myRankData!['avatar_url'] == null
                        ? Text(_myRankData!['nama'][0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                        : null,
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
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> data, double size) {
    bool isJuara1 = data['rank'] == 1;
    bool hasAvatar = data['avatar_url'] != null;

    return Column(
      children: [
        if (isJuara1)
          const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.workspace_premium,
                  color: Color(0xFFFFD700), size: 32)),
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
            backgroundImage:
                hasAvatar ? _getAvatarImage(data['avatar_url']) : null,
            child: !hasAvatar
                ? Text(data['nama'][0].toUpperCase(),
                    style: TextStyle(
                        fontSize: isJuara1 ? 24 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87))
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data['nama'].split(" ")[0],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
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
