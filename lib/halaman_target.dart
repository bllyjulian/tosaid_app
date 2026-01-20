import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. WAJIB IMPORT INI

class HalamanTargetPage extends StatefulWidget {
  const HalamanTargetPage({super.key});

  @override
  State<HalamanTargetPage> createState() => _HalamanTargetPageState();
}

class _HalamanTargetPageState extends State<HalamanTargetPage> {
  // --- STATE DATA ---
  int _totalXp = 0;
  int _streakHari = 0;
  bool _isLoading = true;

  // Status Aktivitas 7 Hari Terakhir (Senin - Minggu)
  List<bool> _mingguanAktif = [false, false, false, false, false, false, false];

  // Data Misi
  List<Map<String, dynamic>> _misiHarian = [
    {'judul': 'Login Aplikasi', 'xp': 10, 'selesai': true},
    {'judul': 'Selesaikan 1 Tes TOSA', 'xp': 50, 'selesai': false},
    {'judul': 'Dapat Nilai > 400', 'xp': 100, 'selesai': false},
    {'judul': 'Belajar 30 Menit', 'xp': 20, 'selesai': false},
    {'judul': 'Review Materi Qira\'ah', 'xp': 30, 'selesai': false},
  ];

  @override
  void initState() {
    super.initState();
    _ambilDataStatistik();
  }

  Future<void> _ambilDataStatistik() async {
    // 2. GANTI INI: Ambil User dari FIREBASE, bukan Supabase
    final user = FirebaseAuth.instance.currentUser;
    final supabase = Supabase.instance.client;

    if (user == null) {
      setState(() => _isLoading = false); // Matikan loading biar ga muter terus
      return;
    }

    try {
      // 1. AMBIL TOTAL XP DARI PROFIL
      final profil = await supabase
          .from('profil_siswa')
          .select('total_xp')
          .eq('id', user.uid) // Pakai UID Firebase
          .maybeSingle();

      // 2. AMBIL RIWAYAT BELAJAR
      final riwayat = await supabase
          .from('riwayat_skor')
          .select('created_at, skor_akhir')
          .eq('user_id', user.uid) // Pakai UID Firebase
          .order('created_at', ascending: false);

      List<dynamic> dataRiwayat = riwayat as List<dynamic>;

      // --- LOGIKA HITUNG STREAK ---
      Set<String> tanggalBelajar = {};
      int skorTertinggiHariIni = 0;
      int jumlahTesHariIni = 0;
      String hariIniStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (var item in dataRiwayat) {
        DateTime tgl = DateTime.parse(item['created_at']).toLocal();
        String tglStr = DateFormat('yyyy-MM-dd').format(tgl);
        tanggalBelajar.add(tglStr);

        if (tglStr == hariIniStr) {
          jumlahTesHariIni++;
          int skor = item['skor_akhir'] ?? 0;
          if (skor > skorTertinggiHariIni) skorTertinggiHariIni = skor;
        }
      }

      // Hitung Streak Mundur
      int currentStreak = 0;
      DateTime checkDate = DateTime.now();

      // Cek hari ini
      if (tanggalBelajar.contains(DateFormat('yyyy-MM-dd').format(checkDate))) {
        currentStreak++;
      }

      // Cek kemarin dst
      while (true) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        String checkStr = DateFormat('yyyy-MM-dd').format(checkDate);
        if (tanggalBelajar.contains(checkStr)) {
          currentStreak++;
        } else {
          break;
        }
      }

      // --- LOGIKA KALENDER MINGGUAN ---
      List<bool> tempMingguan = [
        false,
        false,
        false,
        false,
        false,
        false,
        false
      ];
      DateTime now = DateTime.now();
      DateTime seninMingguIni = now.subtract(Duration(days: now.weekday - 1));

      for (int i = 0; i < 7; i++) {
        DateTime hariCek = seninMingguIni.add(Duration(days: i));
        String strCek = DateFormat('yyyy-MM-dd').format(hariCek);
        if (tanggalBelajar.contains(strCek)) {
          tempMingguan[i] = true;
        }
      }

      if (mounted) {
        setState(() {
          _totalXp = profil != null ? (profil['total_xp'] ?? 0) : 0;
          _streakHari = currentStreak;
          _mingguanAktif = tempMingguan;

          // Update Misi
          if (jumlahTesHariIni > 0) _misiHarian[1]['selesai'] = true;
          if (skorTertinggiHariIni > 400) _misiHarian[2]['selesai'] = true;

          _isLoading = false; // Matikan loading setelah selesai
        });
      }
    } catch (e) {
      print("Error target: $e");
      if (mounted)
        setState(() => _isLoading = false); // Pastikan mati kalau error
    }
  }

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
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER STATISTIK
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
                        Column(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Colors.orange, size: 32),
                            const SizedBox(height: 8),
                            Text("$_streakHari Hari",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            const Text("Streak",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        Container(height: 40, width: 1, color: Colors.white24),
                        Column(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.yellow, size: 32),
                            const SizedBox(height: 8),
                            Text("$_totalXp",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            const Text("Total XP",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        Container(height: 40, width: 1, color: Colors.white24),
                        Column(
                          children: [
                            const Icon(Icons.track_changes,
                                color: Colors.white, size: 32),
                            const SizedBox(height: 8),
                            Text(
                                "${(_misiHarian.where((e) => e['selesai']).length / _misiHarian.length * 100).toInt()}%",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            const Text("Misi Selesai",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. KALENDER MINGGUAN
                  const Text("Aktivitas Minggu Ini",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _HariCircle(hari: "S", aktif: _mingguanAktif[0]),
                        _HariCircle(hari: "S", aktif: _mingguanAktif[1]),
                        _HariCircle(hari: "R", aktif: _mingguanAktif[2]),
                        _HariCircle(hari: "K", aktif: _mingguanAktif[3]),
                        _HariCircle(hari: "J", aktif: _mingguanAktif[4]),
                        _HariCircle(hari: "S", aktif: _mingguanAktif[5]),
                        _HariCircle(hari: "M", aktif: _mingguanAktif[6]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. MISI HARIAN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Misi Harian",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Reset tiap hari",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ..._misiHarian.map((misi) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                                color: misi['selesai']
                                    ? Colors.green
                                    : Colors.grey[200],
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: misi['selesai']
                                        ? Colors.green
                                        : Colors.grey),
                              ),
                              child: misi['selesai']
                                  ? const Icon(Icons.check,
                                      size: 18, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
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
                          if (misi['selesai'])
                            const Icon(Icons.wallet_giftcard,
                                color: Colors.orange),
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
        aktif
            ? const Icon(Icons.check_circle, size: 14, color: Colors.green)
            : const SizedBox(height: 14),
      ],
    );
  }
}
