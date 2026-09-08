import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Messages'),
      ),
      body: currentUser == null
          ? const Center(
              child: Text(
                'You must be logged in to view messages.',
              ),
            )
          : StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .where(
                    'participantIds',
                    arrayContains: currentUser.uid,
                  )
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

                final conversations =
                    snapshot.data!.docs.toList();

                conversations.sort((first, second) {
                  final firstTime =
                      first.data()['updatedAt'] as Timestamp?;

                  final secondTime =
                      second.data()['updatedAt'] as Timestamp?;

                  return (secondTime?.millisecondsSinceEpoch ?? 0)
                      .compareTo(
                    firstTime?.millisecondsSinceEpoch ?? 0,
                  );
                });

                if (conversations.isEmpty) {
                  return const Center(
                    child: Text(
                      'You do not have any messages yet.',
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (context, index) {
                    return const Divider(height: 1);
                  },
                  itemBuilder: (context, index) {
                    final conversationDocument =
                        conversations[index];

                    final conversation =
                        conversationDocument.data();

                    final participantEmails =
                        List<String>.from(
                      conversation['participantEmails'] ??
                          const <String>[],
                    );

                    final readBy = List<String>.from(
                      conversation['readBy'] ??
                          const <String>[],
                    );

                    /*
                     * Empty readBy lists belong to conversations
                     * created before unread tracking was added.
                     */
                    final isUnread = readBy.isNotEmpty &&
                        !readBy.contains(currentUser.uid);

                    var otherUserEmail = 'Student';

                    for (final email in participantEmails) {
                      if (email != currentUser.email) {
                        otherUserEmail = email;
                        break;
                      }
                    }

                    final listingTitle =
                        conversation['listingTitle']
                                as String? ??
                            'Marketplace listing';

                    final lastMessage =
                        conversation['lastMessage']
                                as String? ??
                            '';

                    return Material(
                      color: isUnread
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.35)
                          : Colors.transparent,
                      child: ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            if (isUnread)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          listingTitle,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          lastMessage.isEmpty
                              ? otherUserEmail
                              : lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isUnread
                            ? const Text(
                                'NEW',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                conversationId:
                                    conversationDocument.id,
                                title: otherUserEmail,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}