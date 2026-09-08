import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_page.dart';
import 'home_page.dart';
import 'messages_page.dart';
import 'my_listings_page.dart';
import 'profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {

  int _selectedIndex = 0;

  Future<void> _openConversation(
    String conversationId,
    String sellerName,
  ) async {
    // Select the Messages tab.
    setState(() {
      _selectedIndex = 2;
    });

    // Wait until the Messages tab has been drawn.
    await Future<void>.delayed(Duration.zero);

    if (!mounted) {
      return;
    }

    // Open the actual conversation.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversationId,
          title: sellerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onOpenConversation: _openConversation,
      ),
      const MyListingsPage(),
      const MessagesPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'My Listings',
          ),
          const NavigationDestination(
            icon: _MessagesNavigationIcon(
              selected: false,
            ),
            selectedIcon: _MessagesNavigationIcon(
              selected: true,
            ),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _MessagesNavigationIcon extends StatelessWidget {
  const _MessagesNavigationIcon({
    required this.selected,
  });

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Icon(
        selected
            ? Icons.chat_bubble
            : Icons.chat_bubble_outline,
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where(
            'participantIds',
            arrayContains: currentUser.uid,
          )
          .snapshots(),
      builder: (context, snapshot) {
        var unreadConversations = 0;

        if (snapshot.hasData) {
          unreadConversations =
              snapshot.data!.docs.where((document) {
            final data = document.data();

            final readBy = List<String>.from(
              data['readBy'] ?? const <String>[],
            );

            return readBy.isNotEmpty &&
                !readBy.contains(currentUser.uid);
          }).length;
        }

        return Badge(
          isLabelVisible: unreadConversations > 0,
          label: Text(
            unreadConversations > 99
                ? '99+'
                : unreadConversations.toString(),
          ),
          child: Icon(
            selected
                ? Icons.chat_bubble
                : Icons.chat_bubble_outline,
          ),
        );
      },
    );
  }
}