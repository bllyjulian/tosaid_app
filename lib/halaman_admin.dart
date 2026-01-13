import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'halaman_login.dart'; // Import halaman login buat logout

class HalamanAdminPage extends StatefulWidget {
  const HalamanAdminPage({super.key});

  @override
  State<HalamanAdminPage> createState() => _HalamanAdminPageState();
}

class _HalamanAdminPageState extends State<HalamanAdminPage> {
  // --- CONTROLLER TEXT ---
  final _pertanyaanController = TextEditingController();
  final _opsiAController = TextEditingController();
  final _opsiBController = TextEditingController();
  final _opsiCController = TextEditingController();
  final _opsiDController = TextEditingController();

  // --- VARIABEL STATE ---
  String _selectedKategori = "Istima'";
  String _selectedPola = "Pola 1";
  String? _selectedSubBab; // [BARU] Variabel untuk Sub-Bab
  int _selectedKunci = 0; // 0=A, 1=B, 2=C, 3=D

  // --- VARIABEL AUDIO ---
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  // --- VARIABEL TABEL ---
  List<Map<String, dynamic>> _daftarSoal = [];
  bool _isLoadingTabel = false;

  // --- MAPPING KODE ---
  final Map<String, String> _kodeKategori = {
    "Istima'": "1",
    "Qira'ah": "2",
    "Tarakib": "3"
  };
  final Map<String, String> _kodePola = {
    "Pola 1": "pola1",
    "Pola 2": "pola2",
    "Pola 3": "pola3",
    "Pola 4": "pola4"
  };

  // --- [BARU] DATA SUB-BAB KHUSUS ---
  // Pastikan isinya SAMA PERSIS dengan judul di main.dart
  final Map<String, List<String>> _dataSubBab = {
    "Tarakib - Pola 3": [
      "مُبْتَدَأٌ وَخَبَرٌ", // Mubtada & Khabar
      "كَانَ وَأَخَوَاتُهَا", // Kana wa Akhwatuha
      "إِنَّ وَأَخَوَاتُهَا", // Inna wa Akhwatuha
      "فِعْل وَفَاعِل", // Fi'il wa Fa'il
      "مَفْعُولٌ بِهِ", // Maf'ul Bih
      "نَعْتٌ وَمَنْعُوتٌ", // Na'at wa Man'ut
      "التَّوَابِعُ",
      // At-Tawabi'
      "الْمَفْعُولَاتُ", // Al-Maf'ulat
      "الأَعْدَادُ", // Al-A'dad
    ],
  };

  @override
  void initState() {
    super.initState();
    _resetSubBab(); // Inisialisasi awal
    _ambilDaftarSoal(); // Load data awal
  }

  // [BARU] Reset sub-bab saat kategori/pola berubah
  void _resetSubBab() {
    String key = "$_selectedKategori - $_selectedPola";
    if (_dataSubBab.containsKey(key)) {
      setState(() {
        _selectedSubBab = _dataSubBab[key]![0]; // Default ke item pertama
      });
    } else {
      setState(() {
        _selectedSubBab = null; // Tidak ada sub-bab
      });
    }
  }

  // ==========================================
  // FUNGSI UPLOAD PENGANTAR
  // ==========================================
  void _uploadPengantar() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (result != null) {
      setState(() => _isUploading = true);
      try {
        final supabase = Supabase.instance.client;

        String kodeKat = _kodeKategori[_selectedKategori]!;
        String kodePol = _kodePola[_selectedPola]!;
        String namaFile = "${kodeKat}_${kodePol}_pengantar.mp3";

        final fileBytes = result.files.first.bytes;
        final filePath = result.files.first.path;

        if (kIsWeb) {
          await supabase.storage.from('audio_soal').uploadBinary(
                namaFile,
                fileBytes!,
                fileOptions: const FileOptions(upsert: true),
              );
        } else {
          await supabase.storage.from('audio_soal').upload(
                namaFile,
                File(filePath!),
                fileOptions: const FileOptions(upsert: true),
              );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Audio Pengantar Berhasil Diupload!"),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Gagal: $e"), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // ==========================================
  // 1. FUNGSI AMBIL DATA (REFRESH TABEL)
  // ==========================================
  void _ambilDaftarSoal() async {
    setState(() => _isLoadingTabel = true);
    try {
      // [UPDATE] Menggunakan variable query agar bisa ditambah filter
      var query = Supabase.instance.client
          .from('bank_soal')
          .select()
          .eq('kategori', _selectedKategori)
          .eq('pola', _selectedPola);

      // [BARU] Filter Sub-Bab jika ada
      if (_selectedSubBab != null) {
        query = query.eq('sub_bab', _selectedSubBab!);
      }

      final response = await query.order('id', ascending: true);

      setState(() {
        _daftarSoal = List<Map<String, dynamic>>.from(response);
        _isLoadingTabel = false;
      });
    } catch (e) {
      print("Gagal ambil tabel: $e");
      setState(() => _isLoadingTabel = false);
    }
  }

  // ==========================================
  // 2. FUNGSI PILIH FILE AUDIO SOAL
  // ==========================================
  void _pilihAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  // ==========================================
  // 3. FUNGSI UPLOAD & SIMPAN SOAL
  // ==========================================
  void _uploadSoal() async {
    if (_pertanyaanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pertanyaan wajib diisi!")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      String? audioUrl;

      // A. PROSES UPLOAD AUDIO SOAL
      if (_pickedFile != null) {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String kodeKat = _kodeKategori[_selectedKategori]!;
        String kodePol = _kodePola[_selectedPola]!;
        String namaFile = "${kodeKat}_${kodePol}_$timestamp.mp3";

        if (kIsWeb) {
          await supabase.storage
              .from('audio_soal')
              .uploadBinary(namaFile, _pickedFile!.bytes!);
        } else {
          await supabase.storage
              .from('audio_soal')
              .upload(namaFile, File(_pickedFile!.path!));
        }
        audioUrl = supabase.storage.from('audio_soal').getPublicUrl(namaFile);
      }

      // B. SIMPAN KE DATABASE
      // [UPDATE] Masukkan sub_bab ke dalam data yang dikirim
      final dataKirim = {
        'kategori': _selectedKategori,
        'pola': _selectedPola,
        'pertanyaan': _pertanyaanController.text,
        'audio_url': audioUrl,
        'opsi': [
          _opsiAController.text,
          _opsiBController.text,
          _opsiCController.text,
          _opsiDController.text,
        ],
        'kunci': _selectedKunci,
        'sub_bab': _selectedSubBab, // Kolom baru di database
      };

      await supabase.from('bank_soal').insert(dataKirim);

      // C. BERSIHKAN FORM
      _pertanyaanController.clear();
      _opsiAController.clear();
      _opsiBController.clear();
      _opsiCController.clear();
      _opsiDController.clear();
      setState(() {
        _pickedFile = null;
        _isUploading = false;
      });

      _ambilDaftarSoal(); // Refresh tabel

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Soal Berhasil Disimpan!"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // ==========================================
  // 4. FUNGSI HAPUS SOAL
  // ==========================================
  void _hapusSoal(int id) async {
    bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text("Hapus Soal?"),
                  content: const Text("Yakin ingin menghapus soal ini?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Batal")),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Hapus",
                            style: TextStyle(color: Colors.red))),
                  ],
                )) ??
        false;

    if (confirm) {
      await Supabase.instance.client.from('bank_soal').delete().eq('id', id);
      _ambilDaftarSoal();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Soal dihapus")));
      }
    }
  }

  // ==========================================
  // 5. FUNGSI LOGOUT (Admin Keluar)
  // ==========================================
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Widget _buildOpsiField(
      String label, TextEditingController controller, int valueKunci) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Radio(
            value: valueKunci,
            groupValue: _selectedKunci,
            onChanged: (val) => setState(() => _selectedKunci = val as int),
          ),
          Text("$label. "),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                hintText: "Jawaban $label",
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Halaman Admin"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Keluar",
          )
        ],
      ),
      body: Column(
        children: [
          // ------------------------------------------
          // BAGIAN ATAS: FORM INPUT
          // ------------------------------------------
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pilih Materi:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedKategori,
                          isExpanded: true,
                          items: ["Istima'", "Qira'ah", "Tarakib"]
                              .map((String value) {
                            return DropdownMenuItem<String>(
                                value: value, child: Text(value));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedKategori = val!;
                              _resetSubBab(); // Reset sub bab kalau ganti materi
                            });
                            _ambilDaftarSoal();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedPola,
                          isExpanded: true,
                          items: ["Pola 1", "Pola 2", "Pola 3", "Pola 4"]
                              .map((String value) {
                            return DropdownMenuItem<String>(
                                value: value, child: Text(value));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPola = val!;
                              _resetSubBab(); // Reset sub bab kalau ganti pola
                            });
                            _ambilDaftarSoal();
                          },
                        ),
                      ),
                    ],
                  ),

                  // --- [BARU] DROPDOWN SUB-BAB ---
                  if (_selectedSubBab != null) ...[
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Pilih Materi Spesifik (Sub-Bab):",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
                          DropdownButton<String>(
                            value: _selectedSubBab,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _dataSubBab[
                                    "$_selectedKategori - $_selectedPola"]!
                                .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e,
                                        style: const TextStyle(fontSize: 16))))
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedSubBab = val!);
                              _ambilDaftarSoal();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _uploadPengantar,
                      icon: const Icon(Icons.upload_file, color: Colors.orange),
                      label: const Text(
                          "UPLOAD AUDIO PENGANTAR (Khusus Pola Ini)",
                          style: TextStyle(color: Colors.orange)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Pertanyaan:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _pertanyaanController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Tulis soal di sini..."),
                  ),

                  const SizedBox(height: 20),

                  const Text("File Audio Soal (Opsional):",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pilihAudio,
                        icon:
                            const Icon(Icons.music_note, color: Colors.purple),
                        label: const Text("Pilih MP3"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pickedFile != null
                              ? _pickedFile!.name
                              : "Belum ada file",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: _pickedFile != null
                                  ? Colors.blue
                                  : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    "Akan direname otomatis (Auto timestamp)",
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic),
                  ),

                  const SizedBox(height: 20),

                  const Text("Opsi Jawaban:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildOpsiField("A", _opsiAController, 0),
                  _buildOpsiField("B", _opsiBController, 1),
                  _buildOpsiField("C", _opsiCController, 2),
                  _buildOpsiField("D", _opsiDController, 3),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _uploadSoal,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("UPLOAD SOAL",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(thickness: 5, color: Colors.grey),

          // ------------------------------------------
          // BAGIAN BAWAH: TABEL DAFTAR SOAL
          // ------------------------------------------
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.all(10),
                  // [PERBAIKAN ERROR MERAH DISINI]
                  child: Text(
                    "Daftar Soal: $_selectedKategori - $_selectedPola ${_selectedSubBab != null ? '($_selectedSubBab)' : ''}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: _isLoadingTabel
                      ? const Center(child: CircularProgressIndicator())
                      : _daftarSoal.isEmpty
                          ? const Center(child: Text("Belum ada soal."))
                          : ListView.separated(
                              padding: const EdgeInsets.all(10),
                              itemCount: _daftarSoal.length,
                              separatorBuilder: (c, i) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final soal = _daftarSoal[index];
                                final kunciHuruf =
                                    ['A', 'B', 'C', 'D'][soal['kunci'] ?? 0];
                                final adaAudio = soal['audio_url'] != null &&
                                    soal['audio_url'] != "";

                                return Card(
                                  elevation: 2,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text("${index + 1}"),
                                    ),
                                    title: Text(soal['pertanyaan'] ?? "-",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    subtitle: Row(
                                      children: [
                                        Text("Kunci: $kunciHuruf"),
                                        const SizedBox(width: 10),
                                        if (adaAudio)
                                          const Icon(Icons.mic,
                                              size: 16, color: Colors.green),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _hapusSoal(soal['id']),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
