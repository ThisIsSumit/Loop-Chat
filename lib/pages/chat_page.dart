import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loop_talk/services/database.dart';
import 'package:loop_talk/services/shared_pref.dart';
import 'package:random_string/random_string.dart';

class ChatPage extends StatefulWidget {
  final String name, profileurl, username;

  const ChatPage(
      {required this.name,
      required this.profileurl,
      required this.username,
      super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? myUserName, myName, myEmail, myPicture, chatRoomId, messageId;
  TextEditingController messageController = TextEditingController();
  Stream<QuerySnapshot>? messageStream;
  getTheSharedpref() async {
    myUserName = await SharedPreferencesHelper.getUserName();
    myName = await SharedPreferencesHelper.getName();
    myEmail = await SharedPreferencesHelper.getEmail();
    myPicture = await SharedPreferencesHelper.getImage();
    chatRoomId = getChatRoomIdByUserName(myUserName!, widget.username);
    print("Chatroom ID: $chatRoomId");

    setState(() {});
  }

  onload() async {
    await getTheSharedpref(); // Wait for this to finish
    await getSetMessage(); // Only then call this
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    onload();
  }

  Widget chatMessageTile(String message, bool sendByMe) {
    return Row(
      mainAxisAlignment:
          sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
            child: Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomRight:
                    sendByMe ? Radius.circular(0) : Radius.circular(30),
                topRight: Radius.circular(24),
                bottomLeft: sendByMe ? Radius.circular(30) : Radius.circular(0),
              ),
              color: sendByMe ? Colors.black45 : Colors.blue),
          child: Text(
            message,
            style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ))
      ],
    );
  }

  getSetMessage() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
    setState(() {});
  }

  Widget chatMessage() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return Center(child: Text("No messages yet."));
        }

        print("Fetched ${snapshot.data.docs.length} messages");

        return ListView.builder(
          itemCount: snapshot.data.docs.length,
          reverse: true,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            print(
                "Connection: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, length: ${snapshot.data?.docs.length}");
            return chatMessageTile(
              ds["message"],
              ds["sendBy"] == myUserName,
            );
          },
        );
      },
    );
  }

  getChatRoomIdByUserName(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  void addMessage(bool sendClicked) async {
    if (messageController.text != "") {
      String message = messageController.text;
      messageController.text = "";
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('h:mma').format(now);
      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": myPicture
      };

      //passing id to every message
      messageId = randomAlphaNumeric(10);
      await DatabaseMethods()
          .addMessage(chatRoomId!, messageId!, messageInfoMap);

      Map<String, dynamic> lastMessageInfoMap = {
        "lastMessage": message,
        "lastMessageSendTs": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "lastMessageSendBy": myUserName
      };
      DatabaseMethods().updateLastMessageSend(chatRoomId!, lastMessageInfoMap);
      if (sendClicked) {
        message = "";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff703eff),
      body: Container(
        margin: EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Expanded(
                child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Flexible(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height / 1.25,
                      child: chatMessage(),
                    ),
                  ),
                  SizedBox(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: Color(0xff703eff),
                              borderRadius: BorderRadius.circular(60)),
                          child: Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                                color: Color(0xFFececf8),
                                borderRadius: BorderRadius.circular(10)),
                            child: TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                  suffixIcon: Icon(Icons.attach_file),
                                  border: InputBorder.none,
                                  hintText: "Write your message"),
                              textAlignVertical: TextAlignVertical.center,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10.0,
                        ),
                        GestureDetector(
                          onTap: () {
                            addMessage(true);
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Color(0xff703eff),
                                borderRadius: BorderRadius.circular(60)),
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
