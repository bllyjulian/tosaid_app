import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HalamanKuisPage extends StatefulWidget {
  final String title;
  final String kategoriFilter;
  final String polaFilter;
  final String? subBabFilter;
  final String? instruksi;

  const HalamanKuisPage({
    super.key,
    required this.title,
    required this.kategoriFilter,
    required this.polaFilter,
    this.subBabFilter,
    this.instruksi,
  });

  @override
  State<HalamanKuisPage> createState() => _HalamanKuisPageState();
}

class _HalamanKuisPageState extends State<HalamanKuisPage> {
  int _currentIndex = 0;
  int _score = 0;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  List<Map<String, dynamic>> _soalList = [];
  bool _isLoading = true;

  // --- STATE DRAG & DROP ---
  String? _droppedBox1;
  String? _droppedBox2;
  List<String> _pilihanKataDrag = [];

  // --- [BARU] STATE PILIHAN GANDA (PG) ---
  // List ini akan menyimpan opsi yang sudah diacak beserta status benarnya
  List<Map<String, dynamic>> _opsiPG = [];

  int _tipeLayout = 2;
  String _labelBox1 = "";
  String _labelBox2 = "";

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete
        .listen((event) => setState(() => _isPlaying = false));

    _ambilSoal();

    // Tampilkan instruksi jika ada
    if (widget.instruksi != null && widget.instruksi!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tampilkanDialogInstruksi();
      });
    }
  }

  void _tampilkanDialogInstruksi() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("📝 Petunjuk Pengerjaan",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            widget.instruksi!,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Mulai Mengerjakan",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _bersihkanString(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0640]'), '')
        .replaceAll('إ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('آ', 'ا')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  } // Fungsi baru untuk membuang label a, b, c, d

  String _hapusLabel(String text) {
    return text
        .replaceAll('أ .', '')
        .replaceAll('ب .', '')
        .replaceAll('ج .', '')
        .replaceAll('د .', '')
        .replaceAll('أ.', '') // Hapus Alif + Titik
        .replaceAll('ب.', '') // Hapus Ba + Titik
        .replaceAll('ج.', '') // Hapus Jim + Titik
        .replaceAll('د.', '') // Hapus Dal + Titik
        .trim(); // Hapus spasi berlebih di awal/akhir
  }

  void _tentukanLayout() {
    String subBab = widget.subBabFilter ?? "";
    setState(() {
      if (subBab == "Mubtada Khabar") {
        _tipeLayout = 2;
        _labelBox1 = "Mubtada'";
        _labelBox2 = "Khabar";
      } else if (subBab == "Kana wa Akhwatuha") {
        _tipeLayout = 2;
        _labelBox1 = "Isim Kana";
        _labelBox2 = "Khabar Kana";
      } else if (subBab == "Inna wa Akhwatuha") {
        _tipeLayout = 2;
        _labelBox1 = "Isim Inna";
        _labelBox2 = "Khabar Inna";
      } else if (subBab == "Fi'il Fa'il") {
        _tipeLayout = 2;
        _labelBox1 = "Fi'il";
        _labelBox2 = "Fa'il";
      } else if (subBab == "Na'at wa Man'ut") {
        _tipeLayout = 2;
        _labelBox1 = "Man'ut";
        _labelBox2 = "Na'at";
      } else if (subBab == "Maf'ul bih") {
        _tipeLayout = 1;
        _labelBox1 = "Maf'ul Bih";
      } else if (subBab == "A'dad") {
        _tipeLayout = 1;
        _labelBox1 = "Isi Titik-titik";
      } else if (subBab == "Tawabi'") {
        _tipeLayout = 3;
        _labelBox1 = "Jenis Tawabi'";
      } else if (subBab == "Maf'ulat") {
        _tipeLayout = 3;
        _labelBox1 = "Jenis Maf'ulat";
      } else {
        _tipeLayout = 2;
        _labelBox1 = "Box 1";
        _labelBox2 = "Box 2";
      }
    });
  }

  void _ambilSoal() async {
    try {
      var query = Supabase.instance.client
          .from('bank_soal')
          .select()
          .eq('kategori', widget.kategoriFilter)
          .eq('pola', widget.polaFilter);

      if (widget.subBabFilter != null) {
        query = query.eq('sub_bab', widget.subBabFilter!);
      }

      final response = await query;
      List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(response);

      _tentukanLayout();

      setState(() {
        _soalList = data;
        _isLoading = false;

        // --- SIAPKAN OPSI PERTAMA KALI ---
        if (_soalList.isNotEmpty) {
          if (_isTarakibPola3()) {
            _setupDragDrop(_soalList[0]);
          } else {
            _siapkanOpsiPG(); // Acak opsi untuk soal pertama
          }
        }
      });
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  bool _isTarakibPola3() =>
      widget.kategoriFilter == 'Tarakib' && widget.polaFilter == 'Pola 3';

  // --- [BARU] FUNGSI ACAK OPSI PG ---
  void _siapkanOpsiPG() {
    if (_soalList.isEmpty) return;

    final soal = _soalList[_currentIndex];
    List<dynamic> rawOpsi = soal['opsi'] ?? [];
    int kunciIndex = soal['kunci'] ?? 0;

    List<Map<String, dynamic>> tempOpsi = [];

    // Petakan opsi beserta status kebenarannya
    for (int i = 0; i < rawOpsi.length; i++) {
      tempOpsi.add({
        // --- UBAH BAGIAN INI ---
        'teks': _hapusLabel(
            rawOpsi[i].toString()), // Bersihkan label sebelum masuk list
        // -----------------------
        'isCorrect': i == kunciIndex,
      });
    }

    // ACAK URUTANNYA
    tempOpsi.shuffle();

    // Simpan ke state
    _opsiPG = tempOpsi;
  }

  void _setupDragDrop(Map<String, dynamic> soal) {
    _droppedBox1 = null;
    _droppedBox2 = null;

    if (_tipeLayout == 3) {
      if (_labelBox1 == "Jenis Tawabi'") {
        _pilihanKataDrag = [
          "نَعْت (sifat)",
          "عَطْف (penghubung)",
          "تَوْكِيد (penegas)",
          "بَدَل (pengganti)"
        ];
      } else if (_labelBox1 == "Jenis Maf'ulat") {
        _pilihanKataDrag = [
          "مَفْعُولٌ بِهِ",
          "مَفْعُولٌ فِيهِ",
          "مَفْعُولٌ لِأَجْلِهِ",
          "مَفْعُولٌ مُطْلَق"
        ];
      }
    } else {
      List<dynamic> rawOpsi = soal['opsi'] ?? [];
      _pilihanKataDrag = rawOpsi
          .map((e) => _hapusLabel(e.toString())) // --- TAMBAHKAN INI ---
          .where((kata) => kata.trim().isNotEmpty && kata != "-")
          .toList();
      _pilihanKataDrag.shuffle();
    }
  }

  // --- [UPDATE] Jawab PG menggunakan boolean ---
  void _jawabSoalPG(bool isCorrect) {
    _audioPlayer.stop();
    if (isCorrect) _score += 10;
    _lanjutSoal(); // Langsung lanjut tanpa pop-up
  }

  void _cekJawabanDragDrop() {
    final soal = _soalList[_currentIndex];
    final List<dynamic> opsiAsli = soal['opsi'];
    bool isCorrect = false;

    // Kita bersihkan dulu kunci jawaban dari database biar adil
    String kunci1 = _bersihkanString(_hapusLabel(opsiAsli[0].toString()));
    String kunci2 = (opsiAsli.length > 1)
        ? _bersihkanString(_hapusLabel(opsiAsli[1].toString()))
        : "";

    if (_tipeLayout == 2) {
      if (_droppedBox1 == null || _droppedBox2 == null) return;

      // Bandingkan Jawaban User (yg sudah bersih) dengan Kunci (yg baru dibersihkan)
      if (_bersihkanString(_droppedBox1!) == kunci1 &&
          _bersihkanString(_droppedBox2!) == kunci2) {
        isCorrect = true;
      }
    } else if (_tipeLayout == 1) {
      if (_droppedBox1 == null) return;
      if (_bersihkanString(_droppedBox1!) == kunci1) {
        isCorrect = true;
      }
    } else if (_tipeLayout == 3) {
      if (_droppedBox1 == null) return;
      String userAns = _bersihkanString(_droppedBox1!);
      String dbKey = _bersihkanString(opsiAsli[0].toString());
      if (userAns == dbKey) isCorrect = true;
    }

    if (isCorrect) _score += 10;
    _lanjutSoal();
  }

  void _lanjutSoal() {
    if (_currentIndex < _soalList.length - 1) {
      setState(() {
        _currentIndex++;
        // --- SETUP SOAL BERIKUTNYA ---
        if (_isTarakibPola3()) {
          _setupDragDrop(_soalList[_currentIndex]);
        } else {
          _siapkanOpsiPG(); // Acak opsi lagi untuk soal baru
        }
      });
    } else {
      _tampilkanSkor();
    }
  }

  void _playAudio(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(url));
      }
      setState(() => _isPlaying = !_isPlaying);
    } catch (e) {}
  }

  void _tampilkanSkor() {
    int totalSoal = _soalList.length;
    // Hindari pembagian nol
    double nilaiAkhir = totalSoal > 0 ? (_score / (totalSoal * 10)) * 100 : 0;

    String pesan = "";
    String emoji = "";
    Color warna = Colors.blue;

    if (nilaiAkhir == 100) {
      pesan = "Mumtaz! Luar Biasa!";
      emoji = "🏆";
      warna = Colors.green;
    } else if (nilaiAkhir >= 80) {
      pesan = "Jayyid Jiddan! Sangat Bagus!";
      emoji = "🎉";
      warna = Colors.blue;
    } else if (nilaiAkhir >= 60) {
      pesan = "Jayyid! Bagus!";
      emoji = "👍";
      warna = Colors.orange;
    } else {
      pesan = "Hamasah! Ayo Belajar Lagi!";
      emoji = "💪";
      warna = Colors.redAccent;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 10),
            Text("Nilai Kamu", style: TextStyle(color: Colors.grey[600])),
            Text("$_score",
                style: TextStyle(
                    fontSize: 48, fontWeight: FontWeight.bold, color: warna)),
            const SizedBox(height: 10),
            Text(pesan,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup Dialog
                  Navigator.pop(context); // Kembali ke Halaman Materi
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: warna,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text("Kembali ke Materi",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_soalList.isEmpty)
      return const Scaffold(body: Center(child: Text("Soal tidak ditemukan")));

    final soal = _soalList[_currentIndex];
    final String pertanyaan = soal['pertanyaan'] ?? "";
    final String? pathAudio = soal['audio_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (widget.instruksi != null)
            IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: _tampilkanDialogInstruksi)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Indikator Soal 1/10 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progres Kuis",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(
                  "Soal ${_currentIndex + 1}/${_soalList.length}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: (_currentIndex + 1) / _soalList.length,
                color: Colors.blue,
                backgroundColor: Colors.grey.shade200),
            const SizedBox(height: 20),

            // KOTAK SOAL
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300)),
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (pathAudio != null && pathAudio.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => _playAudio(pathAudio),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: _isPlaying
                              ? Colors.redAccent
                              : const Color(0xFF42A5F5),
                          child: Icon(
                              _isPlaying
                                  ? Icons.pause
                                  : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 30),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(pertanyaan,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // JAWABAN
            _isTarakibPola3()
                ? _buildDragDropContent()
                : _buildPilihanGandaUI(), // Tidak perlu kirim opsi lagi, karena pakai state
          ],
        ),
      ),
    );
  }

  // --- [UPDATE] UI PILIHAN GANDA (Menggunakan list yang sudah diacak) ---
  Widget _buildPilihanGandaUI() {
    return Column(
      children: _opsiPG.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Kirim status isCorrect (true/false) bukan index
              onPressed: () => _jawabSoalPG(item['isCorrect']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Text(item['teks'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDragDropContent() {
    return Column(
      children: [
        if (_tipeLayout == 2)
          Row(children: [
            Expanded(
                child: _buildDropZone(_labelBox1, _droppedBox1,
                    (v) => setState(() => _droppedBox1 = v))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildDropZone(_labelBox2, _droppedBox2,
                    (v) => setState(() => _droppedBox2 = v))),
          ])
        else
          _buildDropZone(_labelBox1, _droppedBox1,
              (v) => setState(() => _droppedBox1 = v)),
        const SizedBox(height: 20),
        const Text("Pilihan Kata:",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _pilihanKataDrag.map((kata) {
            bool isUsed = (kata == _droppedBox1 || kata == _droppedBox2);
            return Draggable<String>(
              data: kata,
              feedback: Material(
                  color: Colors.transparent, child: _chipKata(kata, true)),
              childWhenDragging:
                  Opacity(opacity: 0.3, child: _chipKata(kata, false)),
              child: isUsed
                  ? const SizedBox(width: 50, height: 30)
                  : _chipKata(kata, false),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
              onPressed: _cekJawabanDragDrop,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child:
                  const Text("LANJUT", style: TextStyle(color: Colors.white))),
        )
      ],
    );
  }

  Widget _buildDropZone(
      String label, String? value, Function(String) onAccept) {
    return DragTarget<String>(
      onAccept: onAccept,
      builder: (context, candidate, rejected) {
        return Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: value != null ? Colors.blue.shade50 : Colors.grey.shade100,
            border:
                Border.all(color: value != null ? Colors.blue : Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 5),
            if (value != null)
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue))
            else
              const Icon(Icons.add_circle_outline, color: Colors.grey)
          ]),
        );
      },
    );
  }

  Widget _chipKata(String kata, bool isFeedback) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(20)),
      child: Text(kata,
          style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              decoration: TextDecoration.none)),
    );
  }
}
