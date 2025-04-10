import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loop_talk/pages/chat_page.dart';
import 'package:loop_talk/services/database.dart';

class ChatRoomTile extends StatefulWidget {
  final String chatRoomId;
  final String myUserName;
  final String lastMessage;
  final String time;

  const ChatRoomTile({
    super.key,
    required this.chatRoomId,
    required this.myUserName,
    required this.lastMessage,
    required this.time,
  });

  @override
  State<ChatRoomTile> createState() => _ChatRoomTileState();
}

class _ChatRoomTileState extends State<ChatRoomTile> {
  String profilePicUrl = "", name = "", username = "", id = "";
  bool isLoading = true;

  getThisUserInfo() async {
    try {
      username = widget.chatRoomId
          .replaceAll("_", "")
          .replaceAll(widget.myUserName, "");
      QuerySnapshot querySnapshot =
          await DatabaseMethods().getUserInfo(username);

      if (querySnapshot.docs.isNotEmpty) {
        name = "${querySnapshot.docs[0]["Name"]}";
        id = "${querySnapshot.docs[0]["Id"]}";
        profilePicUrl = "${querySnapshot.docs[0]["Image"]}";
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user info: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    getThisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatPage(
                    name: name,
                    profileurl: profilePicUrl,
                    username: username)));
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Material(
          elevation: 3.0,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: isLoading
                      ? Container(
                          height: 70,
                          width: 70,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : (profilePicUrl.isNotEmpty
                          ? Image.network(
                              profilePicUrl,
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.account_circle,
                                  size: 70,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 70,
                              color: Colors.grey,
                            )),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name.isEmpty ? 'Loading...' : name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        widget.lastMessage.isEmpty
                            ? 'No messages yet'
                            : widget.lastMessage,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                Text(
                  widget.time,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
