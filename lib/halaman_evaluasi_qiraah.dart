import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'halaman_baca_pdf.dart'; // Pastikan file ini ada
import 'halaman_evaluasi_istima.dart'; // Import ini untuk akses HalamanReviewJawaban

class HalamanEvaluasiQiraah extends StatefulWidget {
  const HalamanEvaluasiQiraah({super.key});

  @override
  State<HalamanEvaluasiQiraah> createState() => _HalamanEvaluasiQiraahState();
}

class _HalamanEvaluasiQiraahState extends State<HalamanEvaluasiQiraah> {
  List<Map<String, dynamic>> _daftarSoal = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Jawaban User:
  // Pilihan Ganda -> String ('a')
  // Mengurutkan -> List<String> (['b', 'c', 'a']) - Tersimpan di _daftarSoal['opsi_acak']
  final Map<int, String> _jawabanUserPG = {};

  final AudioPlayer _bgmPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _ambilSoal();
    _bgmPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    super.dispose();
  }

  Future<void> _ambilSoal() async {
    try {
      final response = await Supabase.instance.client
          .from('evaluasi_soal')
          .select()
          .eq('kategori', 'Qiraah')
          .order('id', ascending: true);

      List<Map<String, dynamic>> dataMentah =
          List<Map<String, dynamic>>.from(response);

      // SIAPKAN OPSI (ACAK)
      for (var soal in dataMentah) {
        List<Map<String, String>> opsiList = [];
        if (soal['opsi_a'] != null)
          opsiList.add({'kode': 'a', 'isi': soal['opsi_a']});
        if (soal['opsi_b'] != null)
          opsiList.add({'kode': 'b', 'isi': soal['opsi_b']});
        if (soal['opsi_c'] != null)
          opsiList.add({'kode': 'c', 'isi': soal['opsi_c']});

        // Acak posisi awal
        opsiList.shuffle();
        soal['opsi_acak'] = opsiList;
      }

      setState(() {
        _daftarSoal = dataMentah;
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // Khusus Pilihan Ganda
  void _pilihJawabanPG(String kode) {
    setState(() {
      _jawabanUserPG[_currentIndex] = kode;
    });
  }

  // Khusus Mengurutkan (Reorder)
  void _geserUrutan(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final soal = _daftarSoal[_currentIndex];
      final item = (soal['opsi_acak'] as List).removeAt(oldIndex);
      (soal['opsi_acak'] as List).insert(newIndex, item);
    });
  }

  void _navigasi(int arah) {
    if (arah == 1) {
      // Validasi: Kalau soal PG, harus pilih dulu
      final soal = _daftarSoal[_currentIndex];
      if (soal['tipe_soal'] != 'urutkan' &&
          !_jawabanUserPG.containsKey(_currentIndex)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Pilih jawaban dulu!"),
            duration: Duration(milliseconds: 500)));
        return;
      }

      if (_currentIndex < _daftarSoal.length - 1) {
        setState(() => _currentIndex++);
      } else {
        _selesaiEvaluasi();
      }
    } else {
      if (_currentIndex > 0) {
        setState(() => _currentIndex--);
      }
    }
  }

  // --- HITUNG SKOR & SIAPKAN RIWAYAT ---
  void _selesaiEvaluasi() {
    _bgmPlayer.play(AssetSource('audio/selesai.mp3'));

    int skorTotal = 0;
    int benar = 0;
    List<Map<String, dynamic>> riwayatFinal = [];

    for (int i = 0; i < _daftarSoal.length; i++) {
      var soal = _daftarSoal[i];
      String tipe = soal['tipe_soal'] ?? 'teks';
      String kunci = soal['kunci'] ?? '';
      bool isCorrect = false;
      String jawabanUserStr = "-";
      String kunciStr = "-";

      if (tipe == 'urutkan') {
        // --- LOGIKA MENGURUTKAN ---
        List<dynamic> urutanUserList = soal['opsi_acak'];
        String urutanKode = urutanUserList.map((e) => e['kode']).join(',');

        // Simpan teks urutan user untuk review
        jawabanUserStr = urutanUserList.map((e) => e['isi']).join("\n⬇️\n");

        // Kunci jawaban (Kita perlu susun ulang opsi berdasarkan kunci 'a,b,c')
        List<String> urutanKunci = kunci.split(',');
        List<Map<String, String>> opsiMentah = []; // Harus ambil opsi original
        // Tapi karena opsi sudah diacak, kita bisa cari di list yg ada
        List<dynamic> semuaOpsi = soal['opsi_acak'];

        kunciStr = urutanKunci.map((kode) {
          var item = semuaOpsi.firstWhere((e) => e['kode'] == kode,
              orElse: () => {'isi': '-'});
          return item['isi'];
        }).join("\n⬇️\n");

        if (urutanKode == kunci) {
          isCorrect = true;
          benar++;
        }
      } else {
        // --- LOGIKA PILIHAN GANDA ---
        String? jawaban = _jawabanUserPG[i];

        // Cari Teks Jawaban User
        List<dynamic> opsi = soal['opsi_acak'];
        var opUser = opsi.firstWhere((e) => e['kode'] == jawaban,
            orElse: () => {'isi': '-'});
        jawabanUserStr = opUser['isi'];

        // Cari Teks Kunci
        var opKunci = opsi.firstWhere((e) => e['kode'] == kunci,
            orElse: () => {'isi': '-'});
        kunciStr = opKunci['isi'];

        if (jawaban == kunci) {
          isCorrect = true;
          benar++;
        }
      }

      riwayatFinal.add({
        'pertanyaan': soal['pertanyaan'] ?? "Soal Mengurutkan",
        'jawaban_user': jawabanUserStr,
        'kunci': kunciStr,
        'status': isCorrect
      });
    }

    if (_daftarSoal.isNotEmpty) {
      skorTotal = (benar / _daftarSoal.length * 100).round();
    }

    if (mounted) _tampilkanDialogHasil(skorTotal, riwayatFinal);
  }

  // --- TAMPILAN POP UP HASIL (PREMIUM UI) ---
  void _tampilkanDialogHasil(int skor, List<Map<String, dynamic>> riwayat) {
    // Tentukan Tema
    String pesan = "";
    String emoji = "";
    Color warnaTema = Colors.blue;

    if (skor == 100) {
      pesan = "MUMTAZ!";
      emoji = "🏆";
      warnaTema = Colors.green;
    } else if (skor >= 80) {
      pesan = "JAYYID JIDDAN!";
      emoji = "🎉";
      warnaTema = Colors.blue;
    } else if (skor >= 60) {
      pesan = "JAYYID!";
      emoji = "👍";
      warnaTema = Colors.orange;
    } else {
      pesan = "HAMASAH!";
      emoji = "💪";
      warnaTema = Colors.redAccent;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 40),
              padding: const EdgeInsets.only(
                  top: 60, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pesan,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: warnaTema,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  const Text("Nilai Kamu",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text("$skor",
                      style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87)),

                  const SizedBox(height: 20),

                  // TOMBOL 1: LIHAT JAWABAN
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1976D2)]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => HalamanReviewJawaban(
                                  riwayatJawaban: riwayat))),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: const Text("LIHAT JAWABAN SAYA",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // TOMBOL 2: PEMBAHASAN PDF (QIRA'AH)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HalamanBacaPdf(
                              judul: "Pembahasan Qira'ah",
                              pathPdf:
                                  "assets/pdfs/kj_kuis_qiraah.pdf", // FILE PDF QIRA'AH
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: const Text("PEMBAHASAN (PDF)",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: () {
                      _bgmPlayer.stop();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text("Selesai & Kembali",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: warnaTema, width: 4),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5))
                  ],
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 50)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_daftarSoal.isEmpty)
      return const Scaffold(body: Center(child: Text("Soal Kosong")));

    final soal = _daftarSoal[_currentIndex];
    String tipe = soal['tipe_soal'] ?? 'teks';
    String instruksiText = soal['instruksi'] ?? '-';
    String pertanyaan = soal['pertanyaan'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title:
            Text("Evaluasi Qira'ah ${_currentIndex + 1}/${_daftarSoal.length}"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (instruksiText != '-') ...[
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200)),
                      child: Row(children: [
                        const Icon(Icons.touch_app,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(instruksiText,
                                style: const TextStyle(fontSize: 14)))
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // PERTANYAAN
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.shade200, blurRadius: 10)
                        ]),
                    child: Text(pertanyaan,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Arial'),
                        textDirection: TextDirection.ltr),
                  ),
                  const SizedBox(height: 30),

                  // AREA JAWABAN
                  if (tipe == 'urutkan')
                    _buildSoalUrutkan(soal)
                  else
                    _buildSoalPG(soal),
                ],
              ),
            ),
          ),

          // NAVIGASI
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  TextButton(
                      onPressed: () => _navigasi(-1),
                      child: const Text("Kembali"))
                else
                  const SizedBox(width: 50),
                ElevatedButton(
                  onPressed: () => _navigasi(1),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text(
                      _currentIndex == _daftarSoal.length - 1
                          ? "Selesai"
                          : "Selanjutnya",
                      style: const TextStyle(color: Colors.white)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET PILIHAN GANDA ---
  Widget _buildSoalPG(Map<String, dynamic> soal) {
    List<Map<String, String>> opsiAcak =
        soal['opsi_acak'] as List<Map<String, String>>;
    return Column(
        children: opsiAcak
            .map((opsi) => _tombolTeksPG(opsi['kode']!, opsi['isi']!))
            .toList());
  }

  Widget _tombolTeksPG(String kode, String teks) {
    bool isSelected = _jawabanUserPG[_currentIndex] == kode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _pilihJawabanPG(kode),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.green.shade50 : Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            elevation: isSelected ? 0 : 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: isSelected ? Colors.green : Colors.grey.shade300,
                    width: isSelected ? 2 : 1)),
          ),
          child: Text(teks,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Arial'),
              textDirection: TextDirection.rtl),
        ),
      ),
    );
  }

  // --- WIDGET MENGURUTKAN (DRAG & DROP) ---
  Widget _buildSoalUrutkan(Map<String, dynamic> soal) {
    List<dynamic> items = soal['opsi_acak'];
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      onReorder: _geserUrutan,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => Material(
          elevation: 10,
          color: Colors.transparent,
          shadowColor: Colors.black54,
          child: child),
      itemBuilder: (context, index) {
        final item = items[index];
        return ReorderableDragStartListener(
          key: ValueKey(item['kode']),
          index: index,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 5)
                ]),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text("${index + 1}",
                      style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold))),
              title: Text(item['isi'],
                  style: const TextStyle(
                      fontSize: 18, fontFamily: 'Arial', height: 1.5),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl),
              trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.drag_handle_rounded,
                      color: Colors.grey)),
            ),
          ),
        );
      },
    );
  }
}
