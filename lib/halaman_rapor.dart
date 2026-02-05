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

  // Data
  List<Map<String, dynamic>> _dataTosa = [];
  List<Map<String, dynamic>> _dataLatihan = [];
  List<Map<String, dynamic>> _dataRefleksi = []; // Data baru

  bool _isLoading = true;
  double _rataRataTosa = 0;
  String _predikatRataRata = "-";

  // State untuk tombol FAB (Hanya muncul di tab refleksi)
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    // UBAH LENGTH JADI 3
    _tabController = TabController(length: 3, vsync: this);

    // Listener untuk mendeteksi perpindahan tab (buat hide/show FAB)
    _tabController.addListener(() {
      setState(() {
        _showFab = _tabController.index == 2; // Index 2 adalah Tab Refleksi
      });
    });

    _ambilDataLengkap();
  }

  Future<void> _ambilDataLengkap() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;

      // 1. AMBIL RIWAYAT SKOR (TOSA & LATIHAN)
      final responseSkor = await supabase
          .from('riwayat_skor')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> allData =
          List<Map<String, dynamic>>.from(responseSkor);
      List<Map<String, dynamic>> tosaList = [];
      List<Map<String, dynamic>> latihanList = [];

      for (var item in allData) {
        String jenis = item['jenis'] ?? 'simulasi';
        if (jenis == 'latihan') {
          latihanList.add(item);
        } else {
          tosaList.add(item);
        }
      }

      // Hitung Statistik TOSA
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

      // 2. AMBIL DATA REFLEKSI (BARU)
      final responseRefleksi = await supabase
          .from('refleksi_belajar')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> refleksiList =
          List<Map<String, dynamic>>.from(responseRefleksi);

      if (mounted) {
        setState(() {
          _dataTosa = tosaList;
          _dataLatihan = latihanList;
          _dataRefleksi = refleksiList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error ambil rapor: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FUNGSI INPUT REFLEKSI BARU
  void _bukaFormRefleksi() {
    final TextEditingController c1 = TextEditingController();
    final TextEditingController c2 = TextEditingController();
    final TextEditingController c3 = TextEditingController();
    final TextEditingController c4 = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                    child: Text("Jurnal Refleksi Harian 📝",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold))),
                const SizedBox(height: 20),
                _inputField(
                    "1. Apa yang sudah dipahami?",
                    "Misal: Pola kalimat tanya...",
                    c1,
                    Icons.check_circle_outline,
                    Colors.green),
                _inputField(
                    "2. Kesulitan utama hari ini?",
                    "Misal: Membedakan fi'il...",
                    c2,
                    Icons.warning_amber_rounded,
                    Colors.red),
                _inputField(
                    "3. Strategi belajarmu?",
                    "Misal: Mencatat ulang, nonton video...",
                    c3,
                    Icons.lightbulb_outline,
                    Colors.orange),
                _inputField(
                    "4. Rencana perbaikan besok?",
                    "Misal: Fokus hafalan kosakata...",
                    c4,
                    Icons.rocket_launch_outlined,
                    Colors.blue),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (c1.text.isEmpty || c2.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Isi minimal poin 1 dan 2 ya!")));
                        return;
                      }
                      Navigator.pop(context);
                      await _simpanRefleksi(c1.text, c2.text, c3.text, c4.text);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text("Simpan Jurnal",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _inputField(String label, String hint,
      TextEditingController controller, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: color),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: color.withOpacity(0.05),
        ),
      ),
    );
  }

  Future<void> _simpanRefleksi(
      String p1, String p2, String p3, String p4) async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await Supabase.instance.client.from('refleksi_belajar').insert({
        'user_id': userId,
        'pemahaman': p1,
        'kesulitan': p2,
        'strategi': p3,
        'rencana': p4,
      });
      await _ambilDataLengkap(); // Refresh data
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Refleksi berhasil disimpan!"),
          backgroundColor: Colors.green));
    } catch (e) {
      print("Gagal simpan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTanggal(String isoDate) {
    try {
      DateTime dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Riwayat & Refleksi",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF009688),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF009688),
          tabs: const [
            Tab(text: "Simulasi"),
            Tab(text: "Latihan"),
            Tab(text: "Refleksi"), // TAB BARU
          ],
        ),
      ),

      // TOMBOL FLOATING ACTION (Hanya muncul di Tab Refleksi)
      floatingActionButton: _showFab
          ? FloatingActionButton.extended(
              onPressed: _bukaFormRefleksi,
              backgroundColor: Colors.indigo,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Tulis Jurnal",
                  style: TextStyle(color: Colors.white)),
            )
          : null,

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabSimulasi(),
                _buildTabLatihan(),
                _buildTabRefleksi(), // KONTEN BARU
              ],
            ),
    );
  }

  // === TAB 1: SIMULASI TOSA ===
  Widget _buildTabSimulasi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF009688), Color(0xFF4DB6AC)]),
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
                child: Text("Belum ada riwayat simulasi.",
                    style: TextStyle(color: Colors.grey)))
          else
            ..._dataTosa.map((data) => _buildCardTosa(data)).toList(),
        ],
      ),
    );
  }

  // === TAB 2: LATIHAN MATERI ===
  Widget _buildTabLatihan() {
    if (_dataLatihan.isEmpty)
      return const Center(child: Text("Belum ada riwayat latihan."));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: _dataLatihan.map((data) => _buildCardLatihan(data)).toList(),
      ),
    );
  }

  // === TAB 3: REFLEKSI BELAJAR (BARU & BAGUS) ===
  Widget _buildTabRefleksi() {
    if (_dataRefleksi.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("Belum ada jurnal refleksi.",
                style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 5),
            const Text("Tekan tombol di bawah untuk menulis.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          20, 20, 20, 80), // Padding bawah besar biar gak ketutup FAB
      itemCount: _dataRefleksi.length,
      itemBuilder: (context, index) {
        final data = _dataRefleksi[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.indigo.shade50),
            boxShadow: [
              BoxShadow(
                  color: Colors.indigo.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER TANGGAL
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(_formatTanggal(data['created_at']),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
              ),
              // ISI REFLEKSI
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _itemRefleksi(Icons.check_circle_outline, Colors.green,
                        "Dipahami", data['pemahaman']),
                    const Divider(height: 20),
                    _itemRefleksi(Icons.warning_amber_rounded, Colors.red,
                        "Kesulitan", data['kesulitan']),
                    const Divider(height: 20),
                    _itemRefleksi(Icons.lightbulb_outline, Colors.orange,
                        "Strategi", data['strategi']),
                    const Divider(height: 20),
                    _itemRefleksi(Icons.rocket_launch_outlined, Colors.blue,
                        "Rencana", data['rencana']),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _itemRefleksi(
      IconData icon, Color color, String label, String? content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12, color: color)),
              const SizedBox(height: 4),
              Text(content ?? "-",
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87, height: 1.4)),
            ],
          ),
        )
      ],
    );
  }

  // --- WIDGETS HELPER LAINNYA (SAMA SEPERTI SEBELUMNYA) ---
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
          ]),
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
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16))),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text("Simulasi TOSA",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    "L: ${data['benar_istima']} | S: ${data['benar_tarakib']} | R: ${data['benar_qiraah']}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12))
              ])),
          Text(_formatTanggal(data['created_at']),
              style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCardLatihan(Map<String, dynamic> data) {
    int skor = data['skor_akhir'] ?? 0;
    bool isLemah = skor < 60;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isLemah
              ? Border.all(color: Colors.red.shade100, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 5,
                offset: const Offset(0, 2))
          ]),
      child: Row(
        children: [
          Icon(isLemah ? Icons.warning_amber_rounded : Icons.check_circle,
              color: isLemah ? Colors.red : Colors.green, size: 32),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(data['judul_materi'] ?? "Latihan",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                    isLemah
                        ? "Perlu ditingkatkan lagi!"
                        : "Pemahaman sudah bagus.",
                    style: TextStyle(
                        color: isLemah ? Colors.redAccent : Colors.grey[600],
                        fontSize: 12,
                        fontWeight:
                            isLemah ? FontWeight.bold : FontWeight.normal))
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("$skor",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isLemah ? Colors.red : Colors.green)),
            Text(_formatTanggal(data['created_at']),
                style: TextStyle(color: Colors.grey[400], fontSize: 10))
          ]),
        ],
      ),
    );
  }
}
