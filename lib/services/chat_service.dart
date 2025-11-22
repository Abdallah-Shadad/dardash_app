import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate consistent Room ID
  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join("_");
  }

  // Send Message & Update Room Metadata
  Future<void> sendMessage(
      String receiverId, String text, Map<String, dynamic> receiverData) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    String chatRoomId = getChatRoomId(currentUserId, receiverId);

    Map<String, dynamic> messageData = {
      'senderId': currentUserId,
      'senderEmail': currentEmail,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };

    WriteBatch batch = _firestore.batch();

    // 1. Add Message
    DocumentReference messageRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc();

    batch.set(messageRef, messageData);

    // 2. Update Room Info (For the Chat List)
    DocumentReference roomRef =
        _firestore.collection('chat_rooms').doc(chatRoomId);

    Map<String, dynamic> roomData = {
      'participants': [currentUserId, receiverId],
      'lastMessage': text,
      'lastMessageTime': timestamp,
      'usersInfo': {
        currentUserId: {'email': currentEmail},
        receiverId: {
          'email': receiverData['email'],
          'username': receiverData['username']
        }
      }
    };

    batch.set(roomRef, roomData, SetOptions(merge: true));

    await batch.commit();
  }

  // Stream Messages
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    String chatRoomId = getChatRoomId(userId, otherUserId);
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Stream Chat Rooms (List)
  Stream<QuerySnapshot> getUserChatRooms() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}
