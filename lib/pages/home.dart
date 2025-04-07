import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loop_talk/pages/chat_page.dart';
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

  void getTheSharedpref() async {
    myUserName = await SharedPreferencesHelper.getUserName();
    myName = await SharedPreferencesHelper.getName();
    myEmail = await SharedPreferencesHelper.getEmail();
    myPicture = await SharedPreferencesHelper.getImage();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getTheSharedpref();
  }

  getChatRoomIdByUserName(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  searchUser(String searchQuery) async {
    setState(() {
      isSearching = true;
    });

    if (searchQuery.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    // Get the first character as uppercase for search key
    String searchKey = searchQuery.substring(0, 1).toUpperCase();

    try {
      QuerySnapshot querySnapshot = await DatabaseMethods().search(searchKey);

      // Clear previous results
      setState(() {
        searchResults = [];
      });

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
            setState(() {
              searchResults.add(userData);
            });
          }
        }
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
                  Container(
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
                "LoopTalk",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
            ),
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
                                      searchController.clear();
                                      setState(() {
                                        searchResults = [];
                                        isSearching = false;
                                      });
                                    },
                                  )
                                : null,
                            hintText: "Search UserName"),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Expanded(
                      child: searchResults.isEmpty && isSearching
                          ? Center(
                              child: Text(
                                "No users found",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : searchResults.isNotEmpty
                              ? ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    return buildResultCard(
                                        searchResults[index]);
                                  },
                                )
                              : Center(
                                  child: Text(
                                    "Search for users to chat with",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
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
        });

        var chatRoomId = getChatRoomIdByUserName(myUserName!, data["userName"]);
        Map<String, dynamic> chatInfoMap = {
          "users": [myUserName, data['userName']],
        };

        await DatabaseMethods().createChatRoom(chatRoomId, chatInfoMap);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatPage(
                    name: data['Name'],
                    profileurl: data['Image'],
                    username: data['userName'])));
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
                  child: data["Image"] != null
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

class ChatLog extends StatelessWidget {
  final String imagePath;
  final String userName;
  final String message;
  final String time;

  const ChatLog({
    super.key,
    required this.imagePath,
    required this.userName,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3.0,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 8.0),
        decoration: const BoxDecoration(color: Colors.white54),
        width: MediaQuery.of(context).size.width,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.asset(
                imagePath,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5.0),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              time,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
