import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loop_talk/pages/chat_page.dart';
import 'package:loop_talk/pages/profile_page.dart';
import 'package:loop_talk/services/database.dart';
import 'package:loop_talk/services/shared_pref.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  List<Map<String, dynamic>> searchResults = [];
  String? myUserName, myName, myEmail, myPicture;
  Stream? chatroomStream;

  getTheSharedpref() async {
    myUserName = await SharedPreferencesHelper.getUserName();
    myName = await SharedPreferencesHelper.getName();
    myEmail = await SharedPreferencesHelper.getEmail();
    myPicture = await SharedPreferencesHelper.getImage();
    setState(() {});
  }

  onload() async {
    await getTheSharedpref();
    chatroomStream = await DatabaseMethods().getChatRooms();
    setState(() {});
  }

  @override
  void initState() {
    onload();
    // Add listener to searchController to properly handle text field changes
    searchController.addListener(_onSearchChanged);
    super.initState();
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  // Handle search text changes
  void _onSearchChanged() {
    final text = searchController.text;
    if (text.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
    } else if (text.isNotEmpty && !isSearching) {
      searchUser(text);
    }
  }

  Widget chatRoomList() {
    return StreamBuilder(
        stream: chatroomStream,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return snapshot.hasData && snapshot.data.docs.length > 0
              ? ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.data.docs.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    return ChatRoomTile(
                        chatRoomId: ds.id,
                        myUserName: myUserName!,
                        lastMessage: ds['lastMessage'] ?? "",
                        time: ds['lastMessageSendTs'] ?? "");
                  })
              : Center(
                  child: Text(
                    "No conversations yet!",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
        });
  }

  getChatRoomIdByUserName(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  // Modified to handle empty string case without setting isSearching right away
  searchUser(String searchQuery) async {
    if (searchQuery.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    // Get the first character as uppercase for search key
    String searchKey = searchQuery.substring(0, 1).toUpperCase();

    try {
      QuerySnapshot querySnapshot = await DatabaseMethods().search(searchKey);
      List<Map<String, dynamic>> tempResults = [];

      // Process the search results
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic>? userData = doc.data() as Map<String, dynamic>?;

        if (userData != null &&
            userData['userName'] != null &&
            userData['userName']
                .toString()
                .toUpperCase()
                .startsWith(searchQuery.toUpperCase())) {
          // Don't include current user in search results
          if (userData['userName'] != myUserName) {
            tempResults.add(userData);
          }
        }
      }

      // Update state with results only if we're still searching for the same text
      // This prevents old search results from overriding newer ones
      if (searchController.text == searchQuery) {
        setState(() {
          searchResults = tempResults;
        });
      }
    } catch (e) {
      print("Error searching users: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff703eff),
      body: Container(
        margin: EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/wave.png',
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(width: 10.0),
                  Text(
                    "Hello, ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    myName ?? " User",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfilePage()));
                    },
                    child: Container(
                      padding: EdgeInsets.all(5),
                      margin: EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(
                        Icons.person,
                        color: Color(0xff703eff),
                        size: 25,
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                "Welcome To",
                style: TextStyle(
                    color: const Color.fromARGB(186, 255, 255, 255),
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                "LoopChat",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 30.0, right: 30.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                          color: Color(0xFFececf8),
                          borderRadius: BorderRadius.circular(20)),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          searchUser(value);
                        },
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () {
                                      // Clear text field and ensure isSearching is set to false
                                      setState(() {
                                        searchController.clear();
                                        isSearching = false;
                                        searchResults = [];
                                      });
                                    },
                                  )
                                : null,
                            hintText: "Search UserName"),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: isSearching
                          ? searchResults.isEmpty
                              ? Center(child: Text("No users found"))
                              : ListView.builder(
                                  key: ValueKey<String>("search"),
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    return buildResultCard(
                                        searchResults[index]);
                                  },
                                )
                          : chatRoomList(),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildResultCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () async {
        if (myUserName == null) return;

        setState(() {
          isSearching = false;
          searchController.clear();
          searchResults = [];
        });

        var chatRoomId = getChatRoomIdByUserName(myUserName!, data["userName"]);
        Map<String, dynamic> chatInfoMap = {
          "users": [myUserName, data['userName']],
          "lastMessage": "",
          "lastMessageSendTs": DateTime.now().toString(),
        };

        await DatabaseMethods().createChatRoom(chatRoomId, chatInfoMap);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatPage(
                    name: data['Name'],
                    profileurl: data['Image'],
                    username: data['userName']))).then((_) {
          onload();
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Material(
          elevation: 5.0,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: data["Image"] != null &&
                          data["Image"].toString().isNotEmpty
                      ? Image.network(
                          data["Image"],
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
                        ),
                ),
                SizedBox(width: 20.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data['Name'] ?? 'Name not available',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        data['userName'] ?? '',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
