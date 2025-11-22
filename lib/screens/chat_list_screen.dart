import 'package:chat_app/screens/auth_screen.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dardash Chats",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isSearching ? _buildUserSearchList() : _buildMyChatList(),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _isSearching = val.trim().isNotEmpty;
          });
        },
        decoration: InputDecoration(
          hintText: "Search for users...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildMyChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getUserChatRooms(),
      builder: (context, snapshot) {
        // Error State
        if (snapshot.hasError) {
          return const Center(child: Text("Unable to load chats."));
        }
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Empty State
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("No active chats. Search for a friend!");
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70),
          itemBuilder: (context, index) {
            var roomData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String currentUid = _authService.currentUser!.uid;

            // Identify the other participant
            String otherUid = (roomData['participants'] as List)
                .firstWhere((id) => id != currentUid);

            // Retrieve cached user info
            Map<String, dynamic>? userInfo = roomData['usersInfo']?[otherUid];
            String username = userInfo?['username'] ?? 'Unknown User';
            String email = userInfo?['email'] ?? '';
            String lastMsg = roomData['lastMessage'] ?? '';
            Timestamp? time = roomData['lastMessageTime'];

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(username,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              subtitle: Text(
                lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: time != null
                  ? Text(
                      _formatTime(time),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    )
                  : null,
              onTap: () => _openChat(otherUid, username, email),
            );
          },
        );
      },
    );
  }

  Widget _buildUserSearchList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var users = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String username = data['username'].toString().toLowerCase();
          String email = data['email'].toString().toLowerCase();
          String query = _searchController.text.toLowerCase();

          if (doc.id == _authService.currentUser?.uid) return false;

          return username.contains(query) || email.contains(query);
        }).toList();

        if (users.isEmpty) return _buildEmptyState("No user found");

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var userData = users[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(userData['username']),
              subtitle: Text(userData['email']),
              trailing:
                  const Icon(Icons.message_outlined, color: Color(0xFF4F46E5)),
              onTap: () => _openChat(
                  users[index].id, userData['username'], userData['email']),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _openChat(String id, String name, String email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: id,
          receiverName: name,
          receiverEmail: email,
        ),
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    if (now.day == date.day &&
        now.month == date.month &&
        now.year == date.year) {
      return DateFormat.jm().format(date);
    }
    return DateFormat.yMMMd().format(date);
  }
}
