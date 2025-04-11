import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loop_talk/services/shared_pref.dart';
import 'package:loop_talk/services/firebaseApi.dart';

class DatabaseMethods {
  final FirebaseApi firebaseApi = FirebaseApi();

  Future addUser(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  Future addMessage(String chatRoomId, String messageId,
      Map<String, dynamic> messageInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .set(messageInfoMap);
  }

  Future updateLastMessageSend(
      String chatRoomId, Map<String, dynamic> lastMessageInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(chatRoomId)
        .update(lastMessageInfoMap);
  }

  Future<QuerySnapshot> search(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("SearchKey", isEqualTo: username.substring(0, 1).toUpperCase())
        .get();
  }

  createChatRoom(
      String chatRoomId, Map<String, dynamic> chatRoomInfoMap) async {
    final snapShot = await FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(chatRoomId)
        .get();

    if (snapShot.exists) {
      return true;
    } else {
      return FirebaseFirestore.instance
          .collection("Chatrooms")
          .doc(chatRoomId)
          .set(chatRoomInfoMap);
    }
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("time", descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getUserInfo(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("userName", isEqualTo: username)
        .get();
  }

  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String? myUsername = await SharedPreferencesHelper.getUserName();

    if (myUsername == null) {
      return Stream.empty(); // or throw an exception/log
    }

    return FirebaseFirestore.instance
        .collection("Chatrooms")
        .orderBy("time", descending: true)
        .where("users", arrayContains: myUsername)
        .snapshots();
  }

  // New method to listen for new messages and show notifications
  void listenForNewMessages(String chatRoomId, String currentUserName) {
    FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("time", descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final message = snapshot.docs.first.data();
        final sender = message['sendBy'] as String;
        final messageText = message['message'] as String;

        // Only show notification if the message is from someone else
        if (sender != currentUserName) {
          // Get sender's name from users collection
          final senderInfo = await getUserInfo(sender);
          if (senderInfo.docs.isNotEmpty) {
            final senderName = senderInfo.docs.first['Name'] as String;
            await firebaseApi.showChatNotification(
              senderName: senderName,
              message: messageText,
              chatRoomId: chatRoomId,
            );
          }
        }
      }
    });
  }
}
