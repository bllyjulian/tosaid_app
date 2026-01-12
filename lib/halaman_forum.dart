import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HalamanForumPage extends StatefulWidget {
  const HalamanForumPage({super.key});

  @override
  State<HalamanForumPage> createState() => _HalamanForumPageState();
}

class _HalamanForumPageState extends State<HalamanForumPage> {
  final _pesanController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void kirimPesan() async {
    if (_pesanController.text.trim().isEmpty) return;

    var user = _auth.currentUser;
    var userDoc = await _firestore.collection('users').doc(user!.uid).get();
    String namaPengirim = userDoc.exists ? userDoc['nama'] : "User";

    await _firestore.collection('forum_diskusi').add({
      'text': _pesanController.text,
      'sender': namaPengirim,
      'sender_uid': user.uid,
      'time': FieldValue.serverTimestamp(), // Ini akan menyimpan waktu server
    });

    _pesanController.clear();
  }

  // Fungsi helper untuk memformat jam
  String _formatJam(Timestamp? timestamp) {
    if (timestamp == null)
      return "Sending..."; // Jika data belum sync ke server
    DateTime date = timestamp.toDate();
    // Mengambil jam dan menit, lalu tambahkan 0 di depan jika angkanya satuan (misal 9 jadi 09)
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Forum Diskusi"),
          elevation: 1,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('forum_diskusi')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;
                var currentUser = _auth.currentUser;

                return ListView.builder(
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index].data() as Map<String, dynamic>;
                    String text = data['text'] ?? "";
                    String sender = data['sender'] ?? "Anonim";
                    String senderUid = data['sender_uid'] ?? "";

                    // --- BAGIAN BARU: AMBIL WAKTU ---
                    Timestamp? timeStamp = data['time'];
                    String jamKirim = _formatJam(timeStamp);
                    // --------------------------------

                    bool isMe = (currentUser?.uid == senderUid);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(sender,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold)),
                          Material(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomLeft: isMe
                                  ? const Radius.circular(15)
                                  : Radius.zero,
                              bottomRight: isMe
                                  ? Radius.zero
                                  : const Radius.circular(15),
                            ),
                            elevation: 2,
                            color:
                                isMe ? const Color(0xFFDCF8C6) : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal:
                                      12), // Padding disesuaikan sedikit
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end, // Agar jam di kanan
                                children: [
                                  Text(text,
                                      style: TextStyle(
                                          color: isMe
                                              ? Colors.black87
                                              : Colors.black87)),

                                  const SizedBox(
                                      height: 4), // Jarak antara chat dan jam

                                  // --- WIDGET JAM ---
                                  Text(
                                    jamKirim,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.black54
                                            : Colors.grey[600],
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pesanController,
                    decoration: InputDecoration(
                      hintText: "Tulis pesan...",
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: kirimPesan),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
