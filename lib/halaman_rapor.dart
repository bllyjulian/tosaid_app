import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Jangan lupa: flutter pub add intl
import 'package:firebase_auth/firebase_auth.dart';

class HalamanRaporPage extends StatefulWidget {
  const HalamanRaporPage({super.key});

  @override
  State<HalamanRaporPage> createState() => _HalamanRaporPageState();
}

class _HalamanRaporPageState extends State<HalamanRaporPage> {
  List<Map<String, dynamic>> _riwayatData = [];
  bool _isLoading = true;
  double _rataRataSkor = 0;
  String _predikatRataRata = "-";

  @override
  void initState() {
    super.initState();
    _ambilDataRiwayat();
  }

  Future<void> _ambilDataRiwayat() async {
    try {
      // 1. Ambil User ID dari Firebase Auth
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Definisi Client Supabase (INI YANG TADI KURANG)
      final supabase = Supabase.instance.client;

      // 3. Ambil Data dengan Filter User ID Firebase
      final response = await supabase
          .from('riwayat_skor')
          .select()
          .eq('user_id',
              userId) // Cocokkan UID Firebase dengan kolom user_id (Text) di Supabase
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(response);

      // 4. Hitung Statistik Header
      if (data.isNotEmpty) {
        double total = 0;
        for (var item in data) {
          total += (item['skor_akhir'] as int);
        }
        _rataRataSkor = total / data.length;

        // Hitung predikat rata-rata
        if (_rataRataSkor >= 500) {
          _predikatRataRata = "A";
        } else if (_rataRataSkor >= 400) {
          _predikatRataRata = "B";
        } else if (_rataRataSkor >= 300) {
          _predikatRataRata = "C";
        } else {
          _predikatRataRata = "D";
        }
      } else {
        // Reset jika data kosong
        _rataRataSkor = 0;
        _predikatRataRata = "-";
      }

      setState(() {
        _riwayatData = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error ambil rapor: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatTanggal(String isoDate) {
    try {
      DateTime dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return isoDate;
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. KARTU RINGKASAN (Header Biru Dinamis)
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
                        // Statistik 1
                        Column(
                          children: [
                            const Text("Rata-rata",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 5),
                            Text(_rataRataSkor.toStringAsFixed(0),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(height: 40, width: 1, color: Colors.white24),
                        // Statistik 2
                        Column(
                          children: [
                            const Text("Total Tes",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 5),
                            Text("${_riwayatData.length}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(height: 40, width: 1, color: Colors.white24),
                        // Statistik 3
                        Column(
                          children: [
                            const Text("Predikat",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 5),
                            Text(_predikatRataRata,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text("Riwayat Tes TOSA",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // 2. LIST RIWAYAT NILAI (Dari Supabase)
                  if (_riwayatData.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("Belum ada riwayat tes.")),
                    )
                  else
                    ..._riwayatData.map((data) {
                      return _buildNilaiCard(data);
                    }).toList(),
                ],
              ),
            ),
    );
  }

  // WIDGET KARTU NILAI
  Widget _buildNilaiCard(Map<String, dynamic> data) {
    int skor = data['skor_akhir'];

    // Tentukan warna berdasarkan skor TOSA
    Color warnaBadge;
    if (skor >= 500)
      warnaBadge = Colors.green; // Mumtaz
    else if (skor >= 400)
      warnaBadge = Colors.blue; // Jayyid Jiddan
    else if (skor >= 300)
      warnaBadge = Colors.orange; // Jayyid
    else
      warnaBadge = Colors.red; // Rasib/Maqbul

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
          // Lingkaran Skor
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: warnaBadge.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              "$skor",
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
                const Text("Simulasi TOSA",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                // Rincian Kecil
                Text(
                    "L: ${data['benar_istima']} | S: ${data['benar_tarakib']} | R: ${data['benar_qiraah']}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),

                // Tanggal & Status
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(_formatTanggal(data['created_at']),
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 11)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: warnaBadge.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data['predikat'] ?? "-",
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
        ],
      ),
    );
  }
}
