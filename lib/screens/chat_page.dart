import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();

  bool _isSending = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    _conversationSubscription;

  CollectionReference<Map<String, dynamic>>
      get _messagesReference {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages');
  }

  @override
void initState() {
  super.initState();

  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    return;
  }

  final conversationReference = FirebaseFirestore.instance
      .collection('conversations')
      .doc(widget.conversationId);

  _conversationSubscription =
      conversationReference.snapshots().listen((document) {
    if (!document.exists) {
      return;
    }

    final data = document.data() ?? {};

    final readBy = List<String>.from(
      data['readBy'] ?? const <String>[],
    );

    /*
     * An empty list means this is an older conversation that
     * existed before unread tracking was added.
     */
    if (readBy.isNotEmpty &&
        !readBy.contains(currentUser.uid)) {
      conversationReference.update({
        'readBy': FieldValue.arrayUnion([
          currentUser.uid,
        ]),
      });
    }
  });
}

  @override
  void dispose() {
    _conversationSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (messageText.isEmpty ||
        currentUser == null ||
        _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    final conversationReference = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId);

    try {
      final batch = FirebaseFirestore.instance.batch();

      final messageReference = _messagesReference.doc();

      batch.set(messageReference, {
        'senderId': currentUser.uid,
        'senderEmail': currentUser.email ?? '',
        'text': messageText,
        'sentAt': FieldValue.serverTimestamp(),
      });

      batch.update(conversationReference, {
        'lastMessage': messageText,
        'lastMessageSenderId': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),

        // The sender has read the conversation.
        // Everyone else will now see it as unread.
        'readBy': [currentUser.uid],
      });

      await batch.commit();
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      _messageController.text = messageText;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Could not send the message.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesReference
                  .orderBy('sentAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load messages:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSend the first message below.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data();

                    final isMyMessage =
                        message['senderId'] == currentUser?.uid;

                    return Align(
                      alignment: isMyMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 300,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMyMessage
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          message['text'] as String? ?? '',
                          style: TextStyle(
                            color: isMyMessage
                                ? Colors.white
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization:
                          TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Write a message...',
                      ),
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed:
                        _isSending ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}