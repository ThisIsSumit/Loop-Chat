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
  void getTheSharedpref() async {
    myUserName = await SharedPreferencesHelper.getUserName();
    myName = await SharedPreferencesHelper.getName();
    myEmail = await SharedPreferencesHelper.getEmail();
    myPicture = await SharedPreferencesHelper.getImage();
    chatRoomId = getChatRoomIdByUserName(widget.name, myUserName!);
    setState(() {});
  }

  @override
  void initState() {
    getTheSharedpref();
    super.initState();
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
                  SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: 10),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(30),
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30)),
                        ),
                        child: Text(
                          "How are you ?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30)),
                        ),
                        child: Text(
                          "I am good?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 1.6,
                  ),
                  Container(
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
                        Container(
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
