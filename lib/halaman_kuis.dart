import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'halaman_baca_pdf.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  late AudioPlayer _audioPlayer;
  late AudioPlayer _sfxPlayer;
  bool _isPlaying = false;

  List<Map<String, dynamic>> _soalList = [];
  bool _isLoading = true;

  // --- STATE PENYIMPANAN JAWABAN USER ---
  // PG: Map<IndexSoal, IndexOpsiDipilih>
  final Map<int, int> _jawabanPGUser = {};

  // DragDrop: Map<IndexSoal, Map<NamaBox, StringIsiBox>>
  final Map<int, Map<String, String>> _jawabanDragUser = {};

  // --- STATE LOKAL PER HALAMAN ---
  // Variable ini akan di-reset/di-load setiap ganti soal
  String? _droppedBox1;
  String? _droppedBox2;
  List<String> _pilihanKataDrag = [];
  List<Map<String, dynamic>> _opsiPG = [];

  int _tipeLayout = 2;
  String _labelBox1 = "";
  String _labelBox2 = "";

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();

    _audioPlayer.onPlayerComplete
        .listen((event) => setState(() => _isPlaying = false));

    _ambilSoal();

    if (widget.instruksi != null &&
        widget.instruksi!.isNotEmpty &&
        widget.instruksi != "langsung") {
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
    _sfxPlayer.dispose();
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
  }

  String _hapusLabel(String text) {
    return text
        .replaceAll('أ .', '')
        .replaceAll('ب .', '')
        .replaceAll('ج .', '')
        .replaceAll('د .', '')
        .replaceAll('أ.', '')
        .replaceAll('ب.', '')
        .replaceAll('ج.', '')
        .replaceAll('د.', '')
        .trim();
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
      // 1. Mulai Query (JANGAN pakai .order dulu disini)
      // Gunakan 'PostgrestFilterBuilder' agar bisa ditambah .eq nanti
      var query = Supabase.instance.client
          .from('bank_soal')
          .select(); // Cukup select() dulu

      // 2. Tambahkan Filter Wajib
      // Kita chain (sambung) filter ke variabel query
      query = query.eq('kategori', widget.kategoriFilter);
      query = query.eq('pola', widget.polaFilter);

      // 3. Tambahkan Filter Opsional (Sub Bab)
      if (widget.subBabFilter != null) {
        query = query.eq('sub_bab', widget.subBabFilter!);
      }

      // 4. EKSEKUSI: Tambahkan .order() PALING AKHIR saat await
      // Ini penting! .order mengubah tipe data, jadi harus di akhir.
      final response = await query.order('id', ascending: true);

      List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(response);

      _tentukanLayout();

      setState(() {
        _soalList = data;
        _isLoading = false;

        if (_soalList.isNotEmpty) {
          _siapkanHalamanSoal();
        }
      });
    } catch (e) {
      print("Error ambil soal: $e");
      setState(() => _isLoading = false);
    }
  }

  bool _isTarakibPola3() =>
      widget.kategoriFilter == 'Tarakib' && widget.polaFilter == 'Pola 3';

  // --- FUNGSI UTAMA UNTUK MENYIAPKAN SOAL (RESET/LOAD STATE) ---
  void _siapkanHalamanSoal() {
    _audioPlayer.stop();
    setState(() => _isPlaying = false);

    if (_soalList.isEmpty) return;

    var soal = _soalList[_currentIndex];

    if (_isTarakibPola3()) {
      _siapkanDragDrop(soal);
    } else {
      _siapkanPG(soal);
    }
  }

  // --- SETUP UNTUK PILIHAN GANDA ---
  void _siapkanPG(Map<String, dynamic> soal) {
    List<dynamic> rawOpsi = soal['opsi'] ?? [];
    List<Map<String, dynamic>> tempOpsi = [];

    // Kita simpan index asli (0,1,2,3) agar nanti pencocokan kunci jawaban akurat
    // meskipun tampilannya nanti diatur ulang (tapi requestmu tidak diacak, jadi aman)
    for (int i = 0; i < rawOpsi.length; i++) {
      tempOpsi.add({
        'teks': rawOpsi[i].toString(),
        'indexAsli': i,
      });
    }
    // _opsiPG = tempOpsi; // Kalau mau diacak, pake .shuffle() disini.
    // Sesuai request "jangan diacak", kita biarkan urut.
    setState(() {
      _opsiPG = tempOpsi;
    });
  }

  // --- SETUP UNTUK DRAG & DROP ---
  void _siapkanDragDrop(Map<String, dynamic> soal) {
    // 1. Ambil jawaban yang sudah tersimpan (kalau ada)
    Map<String, String>? savedAns = _jawabanDragUser[_currentIndex];

    _droppedBox1 = savedAns?['box1'];
    _droppedBox2 = savedAns?['box2'];

    // 2. Siapkan kata-kata yang bisa didrag (Pool Kata)
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
          .map((e) => _hapusLabel(e.toString()))
          .where((kata) => kata.trim().isNotEmpty && kata != "-")
          .toList();
      _pilihanKataDrag.shuffle(); // Drag drop tetap diacak di pool-nya
    }

    // 3. Hapus kata yang sudah dipakai di kotak (agar tidak duplikat di bawah)
    if (_droppedBox1 != null) _pilihanKataDrag.remove(_droppedBox1);
    if (_droppedBox2 != null) _pilihanKataDrag.remove(_droppedBox2);

    setState(() {});
  }

  // --- FUNGSI INTERAKSI ---

  // Saat Pilihan Ganda diklik
  void _pilihJawabanPG(int indexAsli) {
    setState(() {
      _jawabanPGUser[_currentIndex] = indexAsli;
    });
  }

  // Saat Drag Drop dilepas
  void _terimaDrop(String boxKey, String val) {
    setState(() {
      if (boxKey == 'box1') {
        // Kembalikan item lama ke pool jika ada
        if (_droppedBox1 != null) _pilihanKataDrag.add(_droppedBox1!);
        _droppedBox1 = val;
      } else {
        if (_droppedBox2 != null) _pilihanKataDrag.add(_droppedBox2!);
        _droppedBox2 = val;
      }
      // Hapus item baru dari pool
      _pilihanKataDrag.remove(val);

      // Simpan ke state global
      _jawabanDragUser[_currentIndex] = {
        'box1': _droppedBox1 ?? "",
        'box2': _droppedBox2 ?? "",
      };
    });
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

  // --- LOGIKA NAVIGASI ---

  void _keSoalSebelumnya() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _siapkanHalamanSoal();
      });
    }
  }

  void _keSoalSelanjutnya() {
    // Validasi: Apakah sudah dijawab?
    bool isAnswered = false;

    if (_isTarakibPola3()) {
      // Drag Drop: Minimal terisi sesuai layout
      if (_tipeLayout == 2) {
        isAnswered = (_droppedBox1 != null && _droppedBox2 != null);
      } else {
        isAnswered = (_droppedBox1 != null);
      }
    } else {
      // PG: Ada index di map jawaban
      isAnswered = _jawabanPGUser.containsKey(_currentIndex);
    }

    if (!isAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jawab dulu sebelum lanjut ya!")),
      );
      return;
    }

    if (_currentIndex < _soalList.length - 1) {
      setState(() {
        _currentIndex++;
        _siapkanHalamanSoal();
      });
    } else {
      // Jika soal terakhir, maka Selesai
      _selesaiKuis();
    }
  }

  // --- LOGIKA HITUNG SKOR (FINAL) ---
  void _selesaiKuis() {
    int skorTotal = 0;
    List<Map<String, dynamic>> riwayatFinal = [];

    for (int i = 0; i < _soalList.length; i++) {
      var soal = _soalList[i];
      bool isCorrect = false;
      String jawabanUserStr = "-";
      String kunciStr = "-";

      if (_isTarakibPola3()) {
        // --- CEK DRAG DROP ---
        var userAns = _jawabanDragUser[i];
        if (userAns != null) {
          List<dynamic> opsiAsli = soal['opsi'];
          String k1 = _bersihkanString(_hapusLabel(opsiAsli[0].toString()));
          String k2 = (opsiAsli.length > 1)
              ? _bersihkanString(_hapusLabel(opsiAsli[1].toString()))
              : "";

          String u1 = _bersihkanString(userAns['box1'] ?? "");
          String u2 = _bersihkanString(userAns['box2'] ?? "");

          // Simpan string utk review
          jawabanUserStr =
              "${_labelBox1}: ${userAns['box1']}\n${_labelBox2}: ${userAns['box2']}";
          kunciStr =
              "${_labelBox1}: ${opsiAsli[0]}\n${_labelBox2}: ${opsiAsli.length > 1 ? opsiAsli[1] : '-'}";

          // Logika Benar/Salah
          if (_tipeLayout == 2) {
            if (u1 == k1 && u2 == k2) isCorrect = true;
          } else if (_tipeLayout == 3) {
            String dbKey = _bersihkanString(opsiAsli[0].toString());
            if (u1 == dbKey) isCorrect = true;
          } else {
            if (u1 == k1) isCorrect = true;
          }
        }
      } else {
        // --- CEK PG ---
        if (_jawabanPGUser.containsKey(i)) {
          int indexUser = _jawabanPGUser[i]!;
          int indexKunci = soal['kunci'] ?? 0;
          List<dynamic> opsi = soal['opsi'];

          jawabanUserStr = opsi[indexUser].toString();
          kunciStr = opsi[indexKunci].toString();

          if (indexUser == indexKunci) isCorrect = true;
        }
      }

      if (isCorrect) skorTotal += 10;

      // Masukkan ke riwayat
      riwayatFinal.add({
        'pertanyaan': soal['pertanyaan'],
        'jawaban_user': jawabanUserStr,
        'kunci': kunciStr,
        'status': isCorrect
      });
    }

    _tampilkanPopUpHasil(skorTotal, riwayatFinal);
  }

  // --- POP UP & SIMPAN ---
  void _playResultSound() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/selesai.mp3'));
    } catch (e) {}
  }

  Future<void> _simpanNilaiLatihan(int skor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final supabase = Supabase.instance.client;
      String namaUser = user.displayName ?? user.email ?? "Siswa";

      // Cek Profil
      final cekUser = await supabase
          .from('profil_siswa')
          .select()
          .eq('id', user.uid)
          .maybeSingle();
      if (cekUser == null) {
        await supabase
            .from('profil_siswa')
            .insert({'id': user.uid, 'nama_siswa': namaUser, 'total_xp': 0});
      }

      String judulBaku =
          "Latihan ${widget.kategoriFilter} ${widget.polaFilter}";
      await supabase.from('riwayat_skor').insert({
        'user_id': user.uid,
        'nama_siswa': namaUser,
        'skor_akhir': skor,
        'jenis': 'latihan',
        'judul_materi': judulBaku,
        'benar_istima': 0,
        'benar_tarakib': 0,
        'benar_qiraah': 0,
        'predikat': skor >= 60 ? 'Lulus' : 'Belum Lulus',
      });
    } catch (e) {
      print("Gagal simpan: $e");
    }
  }

// --- POP UP HASIL (VERSI CANTIK / PREMIUM UI) ---
  void _tampilkanPopUpHasil(int skor, List<Map<String, dynamic>> riwayat) {
    _playResultSound();
    _simpanNilaiLatihan(skor);

    // Hitung persentase
    int totalSoal = _soalList.length;
    double nilaiPersen = totalSoal > 0 ? (skor / (totalSoal * 10)) * 100 : 0;

    // Tentukan Tema Warna & Teks berdasarkan Nilai
    String pesan = "";
    String emoji = "";
    Color warnaTema = Colors.blue;

    if (nilaiPersen == 100) {
      pesan = "MUMTAZ!";
      emoji = "🏆";
      warnaTema = Colors.green;
    } else if (nilaiPersen >= 80) {
      pesan = "JAYYID JIDDAN!";
      emoji = "🎉";
      warnaTema = Colors.blue;
    } else if (nilaiPersen >= 60) {
      pesan = "JAYYID!";
      emoji = "👍";
      warnaTema = Colors.orange;
    } else {
      pesan = "HAMASAH!"; // Semangat!
      emoji = "💪";
      warnaTema = Colors.redAccent;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // User gabisa klik luar untuk tutup
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor:
            Colors.transparent, // Biar background transparan (efek floating)
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none, // Izinkan icon keluar dari kotak
          children: [
            // 1. KOTAK PUTIH UTAMA
            Container(
              margin: const EdgeInsets.only(
                  top: 40), // Jarak biar icon gak kepotong
              padding: const EdgeInsets.only(
                  top: 60, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Tinggi menyesuaikan isi
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

                  // Skor Besar
                  Text("$skor",
                      style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87)),

                  const SizedBox(height: 20),

                  // TOMBOL 1: LIHAT JAWABAN (Gradient Blue)
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
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("LIHAT JAWABAN SAYA",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // TOMBOL 2: PEMBAHASAN PDF (Gradient Green)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        String kat = widget.kategoriFilter;
                        String pol = widget.polaFilter;
                        String pdfFile = "";
                        // Logika nama PDF (singkat)
                        if (kat == "Qira'ah")
                          pdfFile = "2_kj.pdf";
                        else if (kat == "Istima'")
                          pdfFile =
                              "1_kj_${pol.toLowerCase().replaceAll(' ', '')}.pdf";
                        else if (kat == "Tarakib") {
                          if (pol != "Pola 3")
                            pdfFile =
                                "3_kj_${pol.toLowerCase().replaceAll(' ', '')}.pdf";
                          else {
                            List<String> urutan = [
                              "Mubtada Khabar",
                              "Kana wa Akhwatuha",
                              "Inna wa Akhwatuha",
                              "Fi'il Fa'il",
                              "Maf'ul bih",
                              "Na'at wa Man'ut",
                              "Tawabi'",
                              "Maf'ulat",
                              "A'dad"
                            ];
                            int idx =
                                urutan.indexOf(widget.subBabFilter ?? "") + 1;
                            if (idx == 0) idx = 1;
                            pdfFile = "3_kj_pola3_$idx.pdf";
                          }
                        }
                        if (pdfFile.isNotEmpty) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => HalamanBacaPdf(
                                      judul: "Pembahasan",
                                      pathPdf: "assets/pdfs/$pdfFile")));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("PEMBAHASAN (PDF)",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // TOMBOL 3: SELESAI (Simple Text)
                  TextButton(
                    onPressed: () {
                      _sfxPlayer.stop();
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

            // 2. ICON MELAYANG (Floating Icon)
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: warnaTema, width: 4),
                  boxShadow: [
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Bar
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Progres Kuis",
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                        Text("Soal ${_currentIndex + 1}/${_soalList.length}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                      ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                      value: (_currentIndex + 1) / _soalList.length,
                      color: Colors.blue,
                      backgroundColor: Colors.grey.shade200),
                  const SizedBox(height: 20),

                  // Kotak Soal
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: Column(children: [
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
                                    size: 30))),
                        const SizedBox(height: 10),
                      ],
                      Text(pertanyaan,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Area Jawaban
                  _isTarakibPola3()
                      ? _buildDragDropContent()
                      : _buildPilihanGandaUI(),
                ],
              ),
            ),
          ),

          // --- AREA NAVIGASI BAWAH ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))
            ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol KEMBALI
                if (_currentIndex > 0)
                  ElevatedButton.icon(
                    onPressed: _keSoalSebelumnya,
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: const Text("Kembali"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  )
                else
                  const SizedBox(
                      width: 100), // Spacer biar tombol kanan tetap di kanan

                // Tombol SELANJUTNYA / SELESAI
// Tombol SELANJUTNYA / SELESAI (FIXED)
                Directionality(
                  textDirection:
                      TextDirection.rtl, // Ini trik biar icon pindah ke kanan
                  child: ElevatedButton.icon(
                    onPressed: _keSoalSelanjutnya,
                    icon: const Icon(Icons.arrow_back_ios,
                        size: 16,
                        color:
                            Colors.white), // Pakai back_ios karena dibalik RTL
                    label: Text(
                      _currentIndex == _soalList.length - 1
                          ? "Selesai"
                          : "Selanjutnya",
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentIndex == _soalList.length - 1
                          ? Colors.green
                          : Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- UI PILIHAN GANDA (DENGAN HIGHLIGHT) ---
  Widget _buildPilihanGandaUI() {
    // Cek jawaban yang tersimpan untuk soal ini
    int? jawabanTerpilih = _jawabanPGUser[_currentIndex];

    return Column(
      children: _opsiPG.map((item) {
        int idx = item['indexAsli'];
        bool isSelected = (jawabanTerpilih == idx);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _pilihJawabanPG(idx),
              style: ElevatedButton.styleFrom(
                // Warna berubah jika dipilih (Biru Muda vs Putih)
                backgroundColor:
                    isSelected ? Colors.blue.shade50 : Colors.white,
                foregroundColor:
                    isSelected ? Colors.blue.shade900 : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: isSelected ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 2 : 1),
                ),
              ),
              child: Text(item['teks'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- UI DRAG DROP ---
  Widget _buildDragDropContent() {
    return Column(
      children: [
        if (_tipeLayout == 2)
          Row(children: [
            Expanded(
                child: _buildDropZone(
                    _labelBox1, _droppedBox1, (v) => _terimaDrop('box1', v))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildDropZone(
                    _labelBox2, _droppedBox2, (v) => _terimaDrop('box2', v))),
          ])
        else
          _buildDropZone(
              _labelBox1, _droppedBox1, (v) => _terimaDrop('box1', v)),
        const SizedBox(height: 20),
        const Text("Pilihan Kata:",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _pilihanKataDrag.map((kata) {
            return Draggable<String>(
              data: kata,
              feedback:
                  Material(color: Colors.transparent, child: _chipKata(kata)),
              childWhenDragging: Opacity(opacity: 0.3, child: _chipKata(kata)),
              child: _chipKata(kata),
            );
          }).toList(),
        ),
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

  Widget _chipKata(String kata) {
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

class HalamanReviewJawaban extends StatelessWidget {
  final List<Map<String, dynamic>> riwayatJawaban;
  const HalamanReviewJawaban({super.key, required this.riwayatJawaban});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Review Jawaban"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: riwayatJawaban.length,
        itemBuilder: (context, index) {
          final data = riwayatJawaban[index];
          bool isCorrect = data['status'];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Soal ${index + 1}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red)
                        ]),
                    const SizedBox(height: 8),
                    Text(data['pertanyaan'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text("Jawaban Kamu: ${data['jawaban_user']}",
                        style: TextStyle(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold)),
                    if (!isCorrect)
                      Text("Kunci: ${data['kunci']}",
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                  ]),
            ),
          );
        },
      ),
    );
  }
}
