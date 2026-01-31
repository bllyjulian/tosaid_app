import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HalamanRaporPage extends StatefulWidget {
  const HalamanRaporPage({super.key});

  @override
  State<HalamanRaporPage> createState() => _HalamanRaporPageState();
}

class _HalamanRaporPageState extends State<HalamanRaporPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data Terpisah
  List<Map<String, dynamic>> _dataTosa = [];
  List<Map<String, dynamic>> _dataLatihan = [];

  bool _isLoading = true;
  double _rataRataTosa = 0;
  String _predikatRataRata = "-";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ambilDataRiwayat();
  }

  Future<void> _ambilDataRiwayat() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;

      // Ambil SEMUA data skor
      final response = await supabase
          .from('riwayat_skor')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> allData =
          List<Map<String, dynamic>>.from(response);

      // Pisahkan Data: TOSA vs Latihan
      List<Map<String, dynamic>> tosaList = [];
      List<Map<String, dynamic>> latihanList = [];

      for (var item in allData) {
        // Cek kolom 'jenis'. Kalau null, anggap simulasi (data lama)
        String jenis = item['jenis'] ?? 'simulasi';

        if (jenis == 'latihan') {
          latihanList.add(item);
        } else {
          tosaList.add(item);
        }
      }

      // Hitung Statistik Khusus TOSA (Biar akurat)
      if (tosaList.isNotEmpty) {
        double total = 0;
        for (var item in tosaList) {
          total += (item['skor_akhir'] as int);
        }
        _rataRataTosa = total / tosaList.length;

        if (_rataRataTosa >= 500)
          _predikatRataRata = "A";
        else if (_rataRataTosa >= 400)
          _predikatRataRata = "B";
        else if (_rataRataTosa >= 300)
          _predikatRataRata = "C";
        else
          _predikatRataRata = "D";
      }

      if (mounted) {
        setState(() {
          _dataTosa = tosaList;
          _dataLatihan = latihanList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error ambil rapor: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTanggal(String isoDate) {
    try {
      DateTime dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Riwayat Belajar",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        // TAB BAR UNTUK NAVIGASI
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF009688),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF009688),
          tabs: const [
            Tab(text: "Simulasi TOSA"),
            Tab(text: "Latihan Materi"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: SIMULASI TOSA
                _buildTabSimulasi(),

                // TAB 2: LATIHAN (Refleksi)
                _buildTabLatihan(),
              ],
            ),
    );
  }

  // === TAB 1: TAMPILAN SIMULASI (Mirip sebelumnya) ===
  Widget _buildTabSimulasi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Statistik TOSA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF009688), Color(0xFF4DB6AC)],
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
                _buildStatItem("Rata-rata", _rataRataTosa.toStringAsFixed(0)),
                Container(height: 40, width: 1, color: Colors.white24),
                _buildStatItem("Total Tes", "${_dataTosa.length}"),
                Container(height: 40, width: 1, color: Colors.white24),
                _buildStatItem("Predikat", _predikatRataRata),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_dataTosa.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 50),
              child: Text("Belum ada riwayat simulasi TOSA.",
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ..._dataTosa.map((data) => _buildCardTosa(data)).toList(),
        ],
      ),
    );
  }

  // === TAB 2: TAMPILAN LATIHAN (REFLEKSI MATERI) ===
  Widget _buildTabLatihan() {
    if (_dataLatihan.isEmpty) {
      return const Center(child: Text("Belum ada riwayat latihan materi."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200)),
            child: Row(
              children: const [
                Icon(Icons.lightbulb_outline, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                        "Perhatikan nilai merah! Itu tandanya kamu perlu mengulang materi tersebut.",
                        style: TextStyle(fontSize: 12, color: Colors.black87))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._dataLatihan.map((data) => _buildCardLatihan(data)).toList(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  // CARD UNTUK SIMULASI TOSA
  Widget _buildCardTosa(Map<String, dynamic> data) {
    int skor = data['skor_akhir'] ?? 0;
    Color color =
        skor >= 400 ? Colors.green : (skor >= 300 ? Colors.blue : Colors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Text("$skor",
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Simulasi TOSA",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    "L: ${data['benar_istima']} | S: ${data['benar_tarakib']} | R: ${data['benar_qiraah']}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(_formatTanggal(data['created_at']),
              style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  // CARD UNTUK LATIHAN (Refleksi Kelemahan)
  Widget _buildCardLatihan(Map<String, dynamic> data) {
    // Skor Latihan biasanya skala 0-100
    int skor = data['skor_akhir'] ?? 0;
    String materi = data['judul_materi'] ?? "Latihan";

    // Logika Refleksi: Jika nilai < 60, dianggap LEMAH (Merah)
    bool isLemah = skor < 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLemah
            ? Border.all(color: Colors.red.shade100, width: 1.5)
            : null, // Border merah kalau lemah
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Icon Status
          Icon(
            isLemah ? Icons.warning_amber_rounded : Icons.check_circle,
            color: isLemah ? Colors.red : Colors.green,
            size: 32,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(materi,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),

                // Pesan Motivasi Kecil
                Text(
                  isLemah
                      ? "Perlu ditingkatkan lagi!"
                      : "Pemahaman sudah bagus.",
                  style: TextStyle(
                      color: isLemah ? Colors.redAccent : Colors.grey[600],
                      fontSize: 12,
                      fontWeight:
                          isLemah ? FontWeight.bold : FontWeight.normal),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$skor",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isLemah ? Colors.red : Colors.green)),
              Text(_formatTanggal(data['created_at']),
                  style: TextStyle(color: Colors.grey[400], fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}
