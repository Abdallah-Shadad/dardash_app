import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  // Instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generates a consistent Chat Room ID for any two users.
  /// By sorting IDs, 'userA_userB' is always the same as 'userB_userA'.
  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join("_");
  }

  /// Sends a message and updates the Chat Room metadata in one batch operation.
  Future<void> sendMessage(
      String receiverId, String text, Map<String, dynamic> receiverData) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    String chatRoomId = getChatRoomId(currentUserId, receiverId);

    // 1. Prepare Message Data
    Map<String, dynamic> messageData = {
      'senderId': currentUserId,
      'senderEmail': currentEmail,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };

    // 2. Use a Batch Write for Atomicity (Performance & Reliability)
    WriteBatch batch = _firestore.batch();

    // A. Add message to the sub-collection
    DocumentReference messageRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc();

    batch.set(messageRef, messageData);

    // B. Update the Chat Room metadata (Latest message, time, participants)
    // This allows us to fetch the chat list without querying every single message.
    DocumentReference roomRef =
        _firestore.collection('chat_rooms').doc(chatRoomId);

    Map<String, dynamic> roomData = {
      'participants': [currentUserId, receiverId], // Array for fast querying
      'lastMessage': text,
      'lastMessageTime': timestamp,
      'usersInfo': {
        // Store basic info here to avoid fetching the 'users' collection again
        currentUserId: {'email': currentEmail},
        receiverId: {
          'email': receiverData['email'],
          'username': receiverData['username']
        }
      }
    };

    // Merge ensures we don't overwrite existing data unrelated to this update
    batch.set(roomRef, roomData, SetOptions(merge: true));

    // Commit both operations
    await batch.commit();
  }

  /// Stream real-time messages for a specific conversation
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    String chatRoomId = getChatRoomId(userId, otherUserId);
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Stream the list of chats for the current user.
  /// Highly optimized: Only queries documents where the user is a participant.
  Stream<QuerySnapshot> getUserChatRooms() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}
