import 'package:flutter/material.dart';
import 'package:loop_talk/pages/onboarding.dart';
import 'package:loop_talk/services/auth.dart';
import 'package:loop_talk/services/shared_pref.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? myUserName, myName, myEmail, myPicture;

  getTheSharedpref() async {
    myUserName = await SharedPreferencesHelper.getUserName();
    myName = await SharedPreferencesHelper.getName();
    myEmail = await SharedPreferencesHelper.getEmail();
    myPicture = await SharedPreferencesHelper.getImage();
    setState(() {});
  }

  @override
  void initState() {
    getTheSharedpref();
    super.initState();
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // To balance layout and keep text centered visually
                  SizedBox(
                    width: 44, // Similar width as back button to balance it
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            myName == null
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30)),
                          color: Colors.white,
                        ),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 20),

                                // Profile image with elevation
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.network(
                                        myPicture!,
                                        fit: BoxFit.cover,
                                      )),
                                ),

                                SizedBox(height: 30),

                                // Name section - icon above text
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 30,
                                    ),
                                    Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Name',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          myName!,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 24),

                                // Email section - icon above text
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email,
                                      size: 40,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Email',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          myEmail!,
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 40),

                                // Log Out Button with icon
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await AuthMethods().signOut();
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  Onboarding()));
                                    },
                                    icon:
                                        Icon(Icons.logout, color: Colors.white),
                                    label: Text(
                                      'Log Out',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 40, vertical: 12),
                                      elevation: 3,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 12),

                                // Delete Account Button with icon
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await AuthMethods().deleteAccount();
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  Onboarding()));
                                    },
                                    icon: Icon(Icons.delete_forever,
                                        color: Colors.white),
                                    label: Text(
                                      'Delete Account',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 12),
                                      elevation: 3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  )
          ],
        ),
      ),
    );
  }
}
