import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('conversations').where('participantIds', arrayContains: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Could not load messages: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.toList()..sort((a, b) {
            final aTime = a.data()['updatedAt'] as Timestamp?;
            final bTime = b.data()['updatedAt'] as Timestamp?;
            return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(aTime?.millisecondsSinceEpoch ?? 0);
          });
          if (docs.isEmpty) return const Center(child: Text('Message a seller from a listing to begin.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final emails = List<String>.from(data['participantEmails'] ?? const []);
              final other = emails.where((e) => e != FirebaseAuth.instance.currentUser?.email).firstOrNull ?? 'Student';
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(data['listingTitle'] as String? ?? 'Marketplace chat'),
                subtitle: Text(data['lastMessage'] as String? ?? other),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(conversationId: doc.id, title: other))),
              );
            },
          );
        },
      ),
    );
  }
}
