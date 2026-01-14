import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'halaman_kelola_simulasi.dart'; // Pastikan import ini ada jika file kelola ada

class HalamanAdminSimulasi extends StatefulWidget {
  const HalamanAdminSimulasi({super.key});

  @override
  State<HalamanAdminSimulasi> createState() => _HalamanAdminSimulasiState();
}

class _HalamanAdminSimulasiState extends State<HalamanAdminSimulasi> {
  // --- STATE PAKET (PARENT) ---
  String _selectedSection = "Istima'";
  String _jenisKonten = "audio";
  final TextEditingController _teksBacaanController = TextEditingController();
  final TextEditingController _judulPaketController = TextEditingController();
  PlatformFile? _audioPaketFile;

  // List draft soal yang akan diupload
  List<Map<String, dynamic>> _draftSoal = [];
  bool _isUploading = false;

  // --- STATE SOAL / INSTRUKSI (CHILD) ---
  final _tanyaCtrl =
      TextEditingController(); // Ini jadi TEKS INSTRUKSI jika mode instruksi
  final _optACtrl = TextEditingController();
  final _optBCtrl = TextEditingController();
  final _optCCtrl = TextEditingController();
  final _optDCtrl = TextEditingController();
  int _kunciSementara = 0;
  PlatformFile? _audioSoalSementara;

  // [BARU] Mode Instruksi
  bool _isInstruksi = false;

  // ... (Fungsi pilih audio paket sama) ...
  void _pilihAudioPaket() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['mp3', 'wav', 'm4a']);
    if (result != null) setState(() => _audioPaketFile = result.files.first);
  }

  void _pilihAudioSoal() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['mp3', 'wav', 'm4a']);
    if (result != null)
      setState(() => _audioSoalSementara = result.files.first);
  }

  void _tambahSoalKeList() {
    // Validasi: Kalau mode SOAL BIASA, opsi A harus diisi.
    // Kalau mode INSTRUKSI, cuma pertanyaan (teks instruksi) yang wajib.
    if (_tanyaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Isi Teks Pertanyaan / Instruksi!")));
      return;
    }

    if (!_isInstruksi && _optACtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Opsi A harus diisi untuk soal PG!")));
      return;
    }

    setState(() {
      _draftSoal.add({
        'tipe': _isInstruksi ? 'instruksi' : 'pg', // Tandai tipenya
        'pertanyaan': _tanyaCtrl.text,
        // Kalau instruksi, opsi kita isi strip "-" biar database gak error not null
        'opsi_a': _isInstruksi ? "-" : _optACtrl.text,
        'opsi_b': _isInstruksi ? "-" : _optBCtrl.text,
        'opsi_c': _isInstruksi ? "-" : _optCCtrl.text,
        'opsi_d': _isInstruksi ? "-" : _optDCtrl.text,
        'kunci': _kunciSementara,
        'file_audio': _audioSoalSementara,
      });
    });

    // Reset Form
    _tanyaCtrl.clear();
    _optACtrl.clear();
    _optBCtrl.clear();
    _optCCtrl.clear();
    _optDCtrl.clear();
    _kunciSementara = 0;
    _audioSoalSementara = null;
    // Jangan reset _isInstruksi biar ga capek klik toggle terus kalau input banyak instruksi
  }

  void _simpanPaketKeDatabase() async {
    if (_draftSoal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Minimal harus ada 1 item!")));
      return;
    }

    setState(() => _isUploading = true);
    try {
      final supabase = Supabase.instance.client;
      String? kontenUrl;

      // 1. Upload Audio Paket
      if (_jenisKonten == 'audio' && _audioPaketFile != null) {
        String fileName = "paket_${DateTime.now().millisecondsSinceEpoch}.mp3";
        if (kIsWeb) {
          await supabase.storage.from('audio_soal').uploadBinary(
              fileName, _audioPaketFile!.bytes!,
              fileOptions: const FileOptions(upsert: true));
        } else {
          await supabase.storage.from('audio_soal').upload(
              fileName, File(_audioPaketFile!.path!),
              fileOptions: const FileOptions(upsert: true));
        }
        kontenUrl = supabase.storage.from('audio_soal').getPublicUrl(fileName);
      } else if (_jenisKonten == 'teks') {
        kontenUrl = _teksBacaanController.text;
      }

      int urutanAman = (DateTime.now().millisecondsSinceEpoch / 1000).round();

      // 2. Simpan Paket
      final resPaket = await supabase
          .from('simulasi_paket')
          .insert({
            'section': _selectedSection,
            'jenis_konten': _jenisKonten,
            'konten_url': kontenUrl,
            'judul_paket': _judulPaketController.text,
            'urutan': urutanAman,
          })
          .select()
          .single();

      int paketId = resPaket['id'];

      // 3. Simpan Item (Soal/Instruksi)
      for (var item in _draftSoal) {
        String? urlAudioSoal;
        if (item['file_audio'] != null) {
          PlatformFile fileAudio = item['file_audio'];
          String fName =
              "soal_${DateTime.now().millisecondsSinceEpoch}_${item.hashCode}.mp3";
          if (kIsWeb) {
            await supabase.storage.from('audio_soal').uploadBinary(
                fName, fileAudio.bytes!,
                fileOptions: const FileOptions(upsert: true));
          } else {
            await supabase.storage.from('audio_soal').upload(
                fName, File(fileAudio.path!),
                fileOptions: const FileOptions(upsert: true));
          }
          urlAudioSoal =
              supabase.storage.from('audio_soal').getPublicUrl(fName);
        }

        await supabase.from('simulasi_soal').insert({
          'paket_id': paketId,
          'tipe': item['tipe'], // Simpan tipe (instruksi/pg)
          'pertanyaan': item['pertanyaan'],
          'opsi_a': item['opsi_a'],
          'opsi_b': item['opsi_b'],
          'opsi_c': item['opsi_c'],
          'opsi_d': item['opsi_d'],
          'kunci': item['kunci'],
          'audio_url': urlAudioSoal,
        });
      }

      setState(() {
        _draftSoal.clear();
        _audioPaketFile = null;
        _teksBacaanController.clear();
        _judulPaketController.clear();
        _isUploading = false;
      });

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Berhasil Disimpan!"),
            backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Simulasi TOSA"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HalamanKelolaSimulasi())),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: PAKET ---
            const Text("1. Info Paket (Induk)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedSection,
              decoration: const InputDecoration(
                  labelText: "Pilih Section", border: OutlineInputBorder()),
              items: ["Istima'", "Qira'ah", "Tarakib"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedSection = val!;
                _jenisKonten = (val == "Istima'") ? "audio" : "teks";
              }),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _judulPaketController,
                decoration: const InputDecoration(
                    labelText: "Judul Paket", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            if (_jenisKonten == 'audio')
              ElevatedButton.icon(
                  onPressed: _pilihAudioPaket,
                  icon: const Icon(Icons.mic),
                  label: Text(_audioPaketFile != null
                      ? _audioPaketFile!.name
                      : "Upload Audio Induk"))
            else
              TextField(
                  controller: _teksBacaanController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      labelText: "Teks Bacaan Arab",
                      border: OutlineInputBorder())),

            const Divider(thickness: 2, height: 40),

            // --- BAGIAN 2: INPUT SOAL / INSTRUKSI ---
            const Text("2. Tambah Item (Soal / Petunjuk)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),

            // [BARU] SWITCH UNTUK MODE INSTRUKSI
            SwitchListTile(
              title: const Text("Ini hanya Petunjuk/Instruksi Audio?",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                  "Aktifkan jika item ini tidak butuh jawaban (hanya didengarkan)"),
              value: _isInstruksi,
              activeColor: Colors.orange,
              onChanged: (val) => setState(() => _isInstruksi = val),
            ),

            TextField(
                controller: _tanyaCtrl,
                maxLines: _isInstruksi
                    ? 3
                    : 1, // Kalau instruksi mungkin teksnya panjang
                decoration: InputDecoration(
                    labelText:
                        _isInstruksi ? "Isi Teks Petunjuk" : "Pertanyaan Soal",
                    border: const OutlineInputBorder(),
                    fillColor: _isInstruksi ? Colors.orange[50] : null,
                    filled: _isInstruksi)),

            if (_selectedSection == "Istima'") ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                  onPressed: _pilihAudioSoal,
                  icon: const Icon(Icons.volume_up),
                  label: Text(_audioSoalSementara != null
                      ? "Audio Terpilih"
                      : "Upload Audio Item (Wajib untuk Instruksi Istima)")),
            ],

            // [LOGIKA] Sembunyikan Opsi Jawaban jika mode Instruksi
            if (!_isInstruksi) ...[
              const SizedBox(height: 10),
              _buildOpsiField("A", _optACtrl, 0),
              _buildOpsiField("B", _optBCtrl, 1),
              _buildOpsiField("C", _optCCtrl, 2),
              _buildOpsiField("D", _optDCtrl, 3),
            ],

            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _tambahSoalKeList,
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isInstruksi ? Colors.orange : Colors.blue),
                child: Text(
                    _isInstruksi
                        ? "Tambahkan Petunjuk ke Daftar"
                        : "Tambahkan Soal ke Daftar",
                    style: const TextStyle(color: Colors.white)),
              ),
            ),

            const SizedBox(height: 20),

            // --- LIST DRAFT ---
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey[100],
              height: 250,
              child: _draftSoal.isEmpty
                  ? const Center(child: Text("Belum ada item ditambahkan"))
                  : ListView.separated(
                      itemCount: _draftSoal.length,
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (c, i) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _draftSoal[i]['tipe'] == 'instruksi'
                              ? Colors.orange
                              : Colors.blue,
                          child: Icon(
                              _draftSoal[i]['tipe'] == 'instruksi'
                                  ? Icons.info
                                  : Icons.question_mark,
                              color: Colors.white,
                              size: 16),
                        ),
                        title: Text(_draftSoal[i]['pertanyaan'],
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_draftSoal[i]['tipe'] == 'instruksi'
                            ? "Jenis: Petunjuk/Instruksi"
                            : "Kunci: ${_draftSoal[i]['kunci']}"),
                        trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _draftSoal.removeAt(i))),
                      ),
                    ),
            ),

            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    onPressed: _isUploading ? null : _simpanPaketKeDatabase,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SIMPAN SEMUA KE DATABASE",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  Widget _buildOpsiField(String label, TextEditingController ctrl, int val) {
    return Row(children: [
      Radio(
          value: val,
          groupValue: _kunciSementara,
          onChanged: (v) => setState(() => _kunciSementara = v as int)),
      Expanded(
          child: TextField(
              controller: ctrl,
              decoration: InputDecoration(labelText: "Opsi $label"))),
    ]);
  }
}
