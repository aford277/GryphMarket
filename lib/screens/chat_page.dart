import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conversationId, required this.title});
  final String conversationId;
  final String title;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _message.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _message.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (text.isEmpty || user == null || _sending) return;
    setState(() => _sending = true);
    _message.clear();
    final conversation = FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId);
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(conversation.collection('messages').doc(), {
        'senderId': user.uid,
        'senderEmail': user.email,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
      });
      batch.update(conversation, {'lastMessage': text, 'updatedAt': FieldValue.serverTimestamp()});
      await batch.commit();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final messages = FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).collection('messages').orderBy('sentAt', descending: true);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: messages.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final data = snapshot.data!.docs[index].data();
                final mine = data['senderId'] == uid;
                final sent = (data['sentAt'] as Timestamp?)?.toDate();
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(data['text'] as String? ?? '', style: TextStyle(color: mine ? Colors.white : null)),
                      if (sent != null) Text(DateFormat.jm().format(sent), style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : null)),
                    ]),
                  ),
                );
              },
            );
          },
        )),
        SafeArea(top: false, child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(child: TextField(controller: _message, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Write a message...'), onSubmitted: (_) => _send())),
            IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
          ]),
        )),
      ]),
    );
  }
}
