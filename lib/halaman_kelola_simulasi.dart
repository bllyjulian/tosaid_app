import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'halaman_edit_simulasi.dart';

class HalamanKelolaSimulasi extends StatefulWidget {
  const HalamanKelolaSimulasi({super.key});

  @override
  State<HalamanKelolaSimulasi> createState() => _HalamanKelolaSimulasiState();
}

class _HalamanKelolaSimulasiState extends State<HalamanKelolaSimulasi> {
  List<Map<String, dynamic>> _daftarPaket = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ambilData();
  }

  Future<void> _ambilData() async {
    try {
      final supabase = Supabase.instance.client;
      // Ambil data paket dan urutkan dari yang terbaru (id desc)
      final response = await supabase
          .from('simulasi_paket')
          .select('*, simulasi_soal(*)') // Ambil juga anak-anak soalnya
          .order('id', ascending: false);

      setState(() {
        _daftarPaket = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _hapusPaket(int idPaket) async {
    // Tampilkan konfirmasi dulu
    bool confirm = await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text("Hapus Paket?"),
                  content: const Text(
                      "Semua soal di dalam paket ini juga akan terhapus permanen."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Batal")),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Hapus",
                            style: TextStyle(color: Colors.red))),
                  ],
                )) ??
        false;

    if (!confirm) return;

    try {
      final supabase = Supabase.instance.client;

      // 1. Hapus Soal-soalnya dulu (Child)
      await supabase.from('simulasi_soal').delete().eq('paket_id', idPaket);

      // 2. Hapus Paketnya (Parent)
      await supabase.from('simulasi_paket').delete().eq('id', idPaket);

      // Refresh List
      _ambilData();

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data berhasil dihapus")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal hapus: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Data Simulasi")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _daftarPaket.isEmpty
              ? const Center(child: Text("Belum ada data paket soal."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _daftarPaket.length,
                  itemBuilder: (context, index) {
                    final paket = _daftarPaket[index];
                    final List soalList = paket['simulasi_soal'] ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: paket['jenis_konten'] == 'audio'
                              ? Colors.blue[100]
                              : Colors.orange[100],
                          child: Icon(
                              paket['jenis_konten'] == 'audio'
                                  ? Icons.mic
                                  : Icons.article,
                              color: Colors.black54),
                        ),
                        title: Text(paket['judul_paket'] ?? "Tanpa Judul",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "${paket['section']} • ${soalList.length} Soal"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // TOMBOL EDIT
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                // Navigasi ke halaman edit dan tunggu hasilnya
                                // Jika true (berhasil edit), refresh list
                                bool? result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        HalamanEditSimulasi(paketData: paket),
                                  ),
                                );
                                if (result == true) _ambilData();
                              },
                            ),
                            // TOMBOL HAPUS
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _hapusPaket(paket['id']),
                            ),
                          ],
                        ),
                        children: [
                          // List Soal di dalam Paket (Hanya preview)
                          Container(
                            color: Colors.grey[50],
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Daftar Soal:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                                const SizedBox(height: 5),
                                ...soalList
                                    .map((soal) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Text("• ${soal['pertanyaan']}",
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                if (soalList.isEmpty)
                                  const Text("- Tidak ada soal -",
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12))
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
