import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HalamanKuisPage extends StatefulWidget {
  final String title;
  final String kategoriFilter;
  final String polaFilter;
  final String? subBabFilter;

  const HalamanKuisPage({
    super.key,
    required this.title,
    required this.kategoriFilter,
    required this.polaFilter,
    this.subBabFilter,
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

  // --- CONFIG UI ---
  int _tipeLayout = 2; // 1=Satu Kotak, 2=Dua Kotak, 3=Klasifikasi
  String _labelBox1 = "";
  String _labelBox2 = "";

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete
        .listen((event) => setState(() => _isPlaying = false));
    _ambilSoal();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // ==========================================
  // [WAJIB ADA] FUNGSI PEMBERSIH HAROKAT
  // ==========================================
  String _normalisasiArab(String text) {
    if (text.isEmpty) return "";
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0640]'), '') // Buang Harokat
        .replaceAll('إ', 'ا') // Ubah Alif Hamzah Bawah -> Alif Biasa
        .replaceAll('أ', 'ا') // Ubah Alif Hamzah Atas -> Alif Biasa
        .replaceAll('آ', 'ا'); // Ubah Alif Mad -> Alif Biasa
  }

  // --- LOGIKA MENENTUKAN TIPE TAMPILAN ---
  void _tentukanLayout() {
    // 1. Ambil judul asli, lalu bersihkan harokatnya
    String subBabRaw = widget.subBabFilter ?? "";
    String subBab = _normalisasiArab(subBabRaw); // Pake yang sudah bersih

    print("Cek Layout: Asli='$subBabRaw' -> Bersih='$subBab'");

    setState(() {
      // Cek menggunakan teks gundul (tanpa harokat)
      if (subBab.contains("مبتدا")) {
        _tipeLayout = 2;
        _labelBox1 = "Mubtada'";
        _labelBox2 = "Khabar";
      } else if (subBab.contains("كان") && subBab.contains("اخواتها")) {
        _tipeLayout = 2;
        _labelBox1 = "Isim Kana";
        _labelBox2 = "Khabar Kana";
      } else if (subBab.contains("ان") && subBab.contains("اخواتها")) {
        _tipeLayout = 2;
        _labelBox1 = "Isim Inna";
        _labelBox2 = "Khabar Inna";
      } else if (subBab.contains("فعل")) {
        _tipeLayout = 2;
        _labelBox1 = "Fi'il";
        _labelBox2 = "Fa'il";
      } else if (subBab.contains("نعت")) {
        _tipeLayout = 2;
        _labelBox1 = "Man'ut";
        _labelBox2 = "Na'at";
      } else if (subBab.contains("مفعول")) {
        // Bedakan Maf'ul Bih dan Maf'ulat
        if (subBab.contains("المفعولات")) {
          _tipeLayout = 3;
          _labelBox1 = "Jenis Maf'ulat";
        } else {
          _tipeLayout = 1;
          _labelBox1 = "Maf'ul Bih";
        }
      } else if (subBab.contains("الاعداد") || subBab.contains("العداد")) {
        _tipeLayout = 1;
        _labelBox1 = "Isi Titik-titik";
      } else if (subBab.contains("التوابع")) {
        // INI UNTUK TAWABI (Sudah dibersihkan harokatnya, pasti kedetect)
        _tipeLayout = 3;
        _labelBox1 = "Jenis Tawabi'";
      } else {
        // Default
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

      _tentukanLayout(); // Panggil fungsi penentu layout

      if (_isTarakibPola3() && data.isNotEmpty) {
        _setupDragDrop(data[0]);
      }

      setState(() {
        _soalList = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error ambil soal: $e");
      setState(() => _isLoading = false);
    }
  }

  bool _isTarakibPola3() =>
      widget.kategoriFilter == 'Tarakib' && widget.polaFilter == 'Pola 3';

  void _setupDragDrop(Map<String, dynamic> soal) {
    _droppedBox1 = null;
    _droppedBox2 = null;

    if (_tipeLayout == 3) {
      // KLASIFIKASI (Tawabi & Maf'ulat)
      if (_labelBox1 == "Jenis Tawabi'") {
        _pilihanKataDrag = ["نَعْت", "عَطْف", "تَوْكِيد", "بَدَل"];
      } else if (_labelBox1 == "Jenis Maf'ulat") {
        _pilihanKataDrag = [
          "مَفْعُولٌ بِهِ",
          "مَفْعُولٌ فِيهِ",
          "مَفْعُولٌ لِأَجْلِهِ",
          "مَفْعُولٌ مُطْلَق"
        ];
      }
    } else {
      // NORMAL (Ambil dari Database untuk tipe 1 dan 2)
      List<dynamic> rawOpsi = soal['opsi'] ?? [];
      _pilihanKataDrag = rawOpsi
          .map((e) => e.toString())
          .where((kata) => kata.trim().isNotEmpty && kata != "-")
          .toList();
      _pilihanKataDrag.shuffle();
    }
  }

  void _jawabSoalPG(int indexJawaban) {
    _audioPlayer.stop();
    int kunci = _soalList[_currentIndex]['kunci'];
    if (indexJawaban == kunci) _score += 10;
    _lanjutSoal();
  }

  void _cekJawabanDragDrop() {
    final soal = _soalList[_currentIndex];
    final List<dynamic> opsiAsli = soal['opsi'];
    bool isCorrect = false;

    if (_tipeLayout == 2) {
      if (_droppedBox1 == null || _droppedBox2 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lengkapi kedua kotak!")));
        return;
      }
      if (_droppedBox1 == opsiAsli[0] && _droppedBox2 == opsiAsli[1])
        isCorrect = true;
    } else {
      // Tipe 1 & 3 (Satu kotak jawaban)
      if (_droppedBox1 == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Isi jawabannya!")));
        return;
      }
      if (_droppedBox1 == opsiAsli[0]) isCorrect = true;
    }

    if (isCorrect) _score += 10;
    _lanjutSoal();
  }

  void _lanjutSoal() {
    if (_currentIndex < _soalList.length - 1) {
      setState(() {
        _currentIndex++;
        if (_isTarakibPola3()) _setupDragDrop(_soalList[_currentIndex]);
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
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Gagal memutar audio")));
    }
  }

  void _tampilkanSkor() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Selesai"),
        content: Text("Nilai Kamu: $_score"),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [PERBAIKAN ERROR MERAH]: Pakai { } untuk If statement
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_soalList.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: const Center(child: Text("Soal tidak ditemukan")));
    }

    final soal = _soalList[_currentIndex];
    final String pertanyaan = soal['pertanyaan'] ?? "Pertanyaan Kosong";
    final String? pathAudio = soal['audio_url'];

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black),

      // [PERBAIKAN OVERFLOW]: SingleChildScrollView
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
                value: (_currentIndex + 1) / _soalList.length,
                color: Colors.blue),
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

            // AREA JAWABAN
            _isTarakibPola3()
                ? _buildDragDropContent()
                : _buildPilihanGandaUI(soal['opsi'] ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildPilihanGandaUI(List<dynamic> opsi) {
    return Column(
      children: opsi.map((pilihan) {
        int index = opsi.indexOf(pilihan);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _jawabSoalPG(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Text(pilihan.toString(),
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
        // AREA DROP
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

        // KATA PILIHAN
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
              child: const Text("CEK JAWABAN",
                  style: TextStyle(color: Colors.white))),
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
