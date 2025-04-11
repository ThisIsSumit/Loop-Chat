import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loop_talk/services/database.dart';
import 'package:loop_talk/services/shared_pref.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _isRecording = false;
  String? _filePath;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  getTheSharedpref() async {
    myUserName = await SharedPreferencesHelper.getUserName();
    myName = await SharedPreferencesHelper.getName();
    myEmail = await SharedPreferencesHelper.getEmail();
    myPicture = await SharedPreferencesHelper.getImage();
    chatRoomId = getChatRoomIdByUserName(myUserName!, widget.username);
    print("Chatroom ID: $chatRoomId");
  }

  onload() async {
    await getTheSharedpref(); // Wait for this to finish
    await getSetMessage(); // Only then call this
    if (mounted) setState(() {});

    // Start listening for new messages with current chatRoomId
    if (chatRoomId != null && myUserName != null) {
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

          if (sender != myUserName) {
            final senderInfo = await DatabaseMethods().getUserInfo(sender);
            if (senderInfo.docs.isNotEmpty) {
              final senderName = senderInfo.docs.first['Name'] as String;
              await DatabaseMethods().firebaseApi.showChatNotification(
                    senderName: senderName,
                    message: messageText,
                    chatRoomId: chatRoomId!,
                    currentChatRoomId:
                        chatRoomId, // Pass current chatRoomId to prevent notification
                  );
            }
          }
        }
      });
    }
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
          child: message.startsWith('https://') && message.endsWith('.jpg')
              ? GestureDetector(
                  onTap: () {
                    // TODO: Implement full screen image view
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: Image.network(
                          message,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    message,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                )
              : Text(
                  message,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
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

  Future<void> _initialize() async {
    await _recorder.openRecorder();
    await _requestPermission();
    var tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio.aac';
  }

  Future _requestPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request;
    }
  }

  Future<void> _startRecording() async {
    await _recorder.startRecorder(toFile: _filePath);
    setState(() {
      _isRecording = true;
      Navigator.pop(context);
      openRecording();
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _uploadFile() async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
      "Your Audio is Uploading Please wait .....",
      style: TextStyle(fontSize: 15.0),
    )));
    File file = File(_filePath!);
    try {
      TaskSnapshot snapshot =
          await FirebaseStorage.instance.ref('uploads/audio.aac').putFile(file);
      String downloadURL = await snapshot.ref.getDownloadURL();
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('h:mma').format(now);
      Map<String, dynamic> messageInfoMap = {
        "Data": "Audio",
        "message": downloadURL,
        "sendBy": myUserName,
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": myPicture
      };
      messageId = randomAlphaNumeric(10);
      await DatabaseMethods()
          .addMessage(chatRoomId!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": "Audio",
          "lastMessageSendTs": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUserName
        };
        DatabaseMethods()
            .updateLastMessageSend(chatRoomId!, lastMessageInfoMap);
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future openRecording() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                child: Column(
                  children: [
                    Text(
                      "Add Voice Note",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins'),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _startRecording();
                      },
                      child: Text("Start Recording Audio"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _uploadFile();
                        Navigator.pop(context);
                      },
                      child: Text("Upload Voice Message"),
                    ),
                  ],
                ),
              ),
            ),
          ));

  Future<void> getImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Your Image is Uploading Please wait .....",
          style: TextStyle(fontSize: 15.0),
        ),
      ));

      File file = File(image.path);
      try {
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${randomAlphaNumeric(6)}.jpg';
        TaskSnapshot snapshot = await FirebaseStorage.instance
            .ref('uploads/images/$fileName')
            .putFile(file);

        String downloadURL = await snapshot.ref.getDownloadURL();
        DateTime now = DateTime.now();
        String formattedDate = DateFormat('h:mma').format(now);

        Map<String, dynamic> messageInfoMap = {
          "Data": "Image",
          "message": downloadURL,
          "sendBy": myUserName,
          "ts": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "imgUrl": myPicture
        };

        messageId = randomAlphaNumeric(10);
        await DatabaseMethods()
            .addMessage(chatRoomId!, messageId!, messageInfoMap)
            .then((value) {
          Map<String, dynamic> lastMessageInfoMap = {
            "lastMessage": "Image",
            "lastMessageSendTs": formattedDate,
            "time": FieldValue.serverTimestamp(),
            "lastMessageSendBy": myUserName
          };
          DatabaseMethods()
              .updateLastMessageSend(chatRoomId!, lastMessageInfoMap);
        });
      } catch (e) {
        print("Error uploading image: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "Error uploading image. Please try again.",
            style: TextStyle(fontSize: 15.0),
          ),
        ));
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
                          GestureDetector(
                            onTap: () {
                              openRecording();
                            },
                            child: Container(
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
                                    suffixIcon: GestureDetector(
                                        onTap: () {
                                          getImage();
                                        },
                                        child: Icon(Icons.attach_file)),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
