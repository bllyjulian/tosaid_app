import 'package:flutter/material.dart';
// 1. SEMBUNYIKAN User DARI SUPABASE BIAR GAK BENTROK DENGAN FIREBASE
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart';

class HalamanLeaderboardPage extends StatefulWidget {
  const HalamanLeaderboardPage({super.key});

  @override
  State<HalamanLeaderboardPage> createState() => _HalamanLeaderboardPageState();
}

class _HalamanLeaderboardPageState extends State<HalamanLeaderboardPage> {
  // State Tab: 0 = Latihan (XP), 1 = Simulasi (TOSA)
  int _selectedTab = 0;

  List<Map<String, dynamic>> _topThree = [];
  List<Map<String, dynamic>> _otherRanks = [];
  Map<String, dynamic>? _myRankData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  // Fungsi Ganti Tab
  void _gantiTab(int index) {
    if (_selectedTab == index) return;
    setState(() {
      _selectedTab = index;
      _isLoading = true;
      _topThree = [];
      _otherRanks = [];
      _myRankData = null;
    });
    _fetchLeaderboard();
  }

  ImageProvider _getAvatarImage(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http'))
        return NetworkImage(url);
      else
        return AssetImage(url);
    }
    return const AssetImage('assets/images/profil.png');
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final supabase = Supabase.instance.client;
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final myUserId = firebaseUser?.uid;

      List<Map<String, dynamic>> processedList = [];

      // ====================================================
      // LOGIKA TAB 1: LEADERBOARD XP (LATIHAN)
      // Sumber: Tabel 'profil_siswa' -> Kolom 'nama'
      // ====================================================
      if (_selectedTab == 0) {
        final response = await supabase
            .from('profil_siswa')
            .select('id, nama, total_xp, avatar_url') // <--- PAKAI 'nama'
            .order('total_xp', ascending: false) // Urutkan XP Tertinggi
            .limit(50);

        List<dynamic> data = response as List<dynamic>;

        for (int i = 0; i < data.length; i++) {
          var item = data[i];
          processedList.add({
            'user_id': item['id'],
            'nama': item['nama'] ?? 'Siswa', // Ambil dari 'nama'
            'skor': item['total_xp'] ?? 0,
            'avatar_url': item['avatar_url'],
            'rank': i + 1,
            'color': _getRankColor(i + 1),
          });
        }
      }

      // ====================================================
      // LOGIKA TAB 2: LEADERBOARD TOSA (SIMULASI)
      // Sumber: Tabel 'riwayat_skor' -> Kolom 'nama_siswa'
      // ====================================================
      else {
        // Ambil skor simulasi tertinggi
        final response = await supabase
            .from('riwayat_skor')
            .select(
                'user_id, nama_siswa, skor_akhir') // <--- PAKAI 'nama_siswa'
            .eq('jenis', 'simulasi')
            .order('skor_akhir', ascending: false);

        List<dynamic> allScores = response as List<dynamic>;

        // Filter: Hanya ambil 1 skor tertinggi per user (Distinct)
        Map<String, Map<String, dynamic>> uniqueUsers = {};

        for (var item in allScores) {
          String uid = item['user_id'];
          // Karena sudah di-order descending, data pertama yang ketemu pasti skor tertinggi user tsb
          if (!uniqueUsers.containsKey(uid)) {
            uniqueUsers[uid] = {
              'user_id': uid,
              'nama': item['nama_siswa'] ?? 'Siswa', // Ambil dari 'nama_siswa'
              'skor': item['skor_akhir'] ?? 0,
              'avatar_url': null, // Riwayat skor tidak punya avatar
            };
          }
        }

        // Konversi Map ke List dan beri Ranking
        int rank = 1;
        uniqueUsers.forEach((key, value) {
          if (rank <= 50) {
            // Limit 50 besar
            value['rank'] = rank;
            value['color'] = _getRankColor(rank);
            processedList.add(value);
            rank++;
          }
        });
      }

      // --- PISAHKAN TOP 3 & MY RANK ---
      if (processedList.length >= 3) {
        // Susunan Podium: Juara 2 (Kiri), Juara 1 (Tengah), Juara 3 (Kanan)
        _topThree = [processedList[1], processedList[0], processedList[2]];
        _otherRanks = processedList.sublist(3);
      } else {
        _topThree = processedList; // Kalau kurang dari 3, tampilkan apa adanya
        _otherRanks = [];
      }

      // Cari Data Saya
      try {
        _myRankData = processedList.firstWhere((e) => e['user_id'] == myUserId);
      } catch (e) {
        _myRankData = null; // Tidak masuk ranking
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print("Error fetch leaderboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Emas
    if (rank == 2) return const Color(0xFFC0C0C0); // Perak
    if (rank == 3) return const Color(0xFFCD7F32); // Perunggu
    return Colors.blue.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Papan Peringkat",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // --- TAB SWITCHER (PILIHAN MENU) ---
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300)),
            child: Row(
              children: [
                _buildTabItem("Latihan (XP)", 0),
                _buildTabItem("Simulasi TOSA", 1),
              ],
            ),
          ),

          // --- KONTEN LIST ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchLeaderboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // BAGIAN PODIUM (TOP 3)
                          if (_topThree.isNotEmpty)
                            Container(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 10, 20, 30),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.blue.withOpacity(0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5))
                                  ]),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _topThree.map((item) {
                                  double size = item['rank'] == 1 ? 110 : 80;
                                  return _buildPodiumItem(item, size);
                                }).toList(),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.leaderboard,
                                      size: 50, color: Colors.grey[300]),
                                  const SizedBox(height: 10),
                                  Text(
                                    _selectedTab == 0
                                        ? "Belum ada yang mengumpulkan XP"
                                        : "Belum ada riwayat Simulasi",
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // LIST RANKING SISANYA (4 dst)
                          if (_otherRanks.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _otherRanks.length,
                              itemBuilder: (context, index) {
                                final item = _otherRanks[index];
                                return _buildRankItem(item);
                              },
                            ),

                          const SizedBox(
                              height:
                                  100), // Spacer bawah biar gak ketutup bar saya
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),

      // BAR POSISI SAYA (Melayang di Bawah)
      bottomNavigationBar: !_isLoading && _myRankData != null
          ? Container(
              height: 70,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Text("#${_myRankData!['rank']}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white)),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _getAvatarImage(_myRankData!['avatar_url']),
                    child: _myRankData!['avatar_url'] == null
                        ? Text(_myRankData!['nama'][0].toUpperCase(),
                            style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Posisi Saya",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        Text("${_myRankData!['nama']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(
                    "${_myRankData!['skor']} ${_selectedTab == 0 ? 'XP' : ''}",
                    style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // --- WIDGET TAB ITEM ---
  Widget _buildTabItem(String title, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _gantiTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue.shade800 : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET PODIUM (JUARA 1, 2, 3) ---
  Widget _buildPodiumItem(Map<String, dynamic> data, double size) {
    bool isJuara1 = data['rank'] == 1;
    return Column(
      children: [
        if (isJuara1)
          const Icon(Icons.workspace_premium,
              color: Color(0xFFFFD700), size: 30),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: data['color'], width: 3),
          ),
          child: CircleAvatar(
            radius: isJuara1 ? 35 : 25,
            backgroundColor: Colors.grey[200],
            backgroundImage: _getAvatarImage(data['avatar_url']),
            child: data['avatar_url'] == null
                ? Text(data['nama'][0].toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black54))
                : null,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(data['nama'].split(" ")[0],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
        Text("${data['skor']} ${_selectedTab == 0 ? 'XP' : ''}",
            style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: data['color'], borderRadius: BorderRadius.circular(10)),
          child: Text("${data['rank']}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // --- WIDGET LIST ITEM (RANK 4 KEBAWAH) ---
  Widget _buildRankItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100)),
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
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: _getAvatarImage(item['avatar_url']),
            child: item['avatar_url'] == null
                ? Text(item['nama'][0].toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                        fontSize: 12))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['nama'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(
            "${item['skor']} ${_selectedTab == 0 ? 'XP' : 'Pt'}",
            style: TextStyle(
                color: Colors.orange.shade800, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
