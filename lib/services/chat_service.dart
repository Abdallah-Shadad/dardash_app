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

  // دالة مساعدة لجلب بيانات المستخدم الحالي (الاسم والإيميل)
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    String uid = _auth.currentUser!.uid;
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  // Send Message & Update Room Metadata
  Future<void> sendMessage(
      String receiverId, String text, Map<String, dynamic> receiverData) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // 1. جلب بياناتي (المرسل) من قاعدة البيانات للتأكد من الاسم
    Map<String, dynamic>? myData = await getCurrentUserData();
    String myName = myData?['username'] ??
        currentEmail
            .split('@')[0]; // لو الاسم مش موجود استخدم الجزء الأول من الإيميل

    String chatRoomId = getChatRoomId(currentUserId, receiverId);

    Map<String, dynamic> messageData = {
      'senderId': currentUserId,
      'senderEmail': currentEmail,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };

    WriteBatch batch = _firestore.batch();

    // 2. Add Message
    DocumentReference messageRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc();

    batch.set(messageRef, messageData);

    // 3. Update Room Info (تحديث بيانات الطرفين لضمان ظهور الأسماء)
    DocumentReference roomRef =
        _firestore.collection('chat_rooms').doc(chatRoomId);

    Map<String, dynamic> roomData = {
      'participants': [currentUserId, receiverId],
      'lastMessage': text,
      'lastMessageTime': timestamp,
      'usersInfo': {
        // بياناتي أنا (المرسل) -> عشان تظهر عنده
        currentUserId: {'email': currentEmail, 'username': myName},
        // بياناته هو (المستقبل) -> بحفظها زي ما هي عشان تظهر عندي
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
