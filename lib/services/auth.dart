import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loop_talk/services/database.dart';
import 'package:loop_talk/services/shared_pref.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;
  getCurrentUser() async {
    return await auth.currentUser;
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication?.idToken,
        accessToken: googleSignInAuthentication?.accessToken);
    UserCredential result = await firebaseAuth.signInWithCredential(credential);
    User? userDetails = result.user;
    String userName = userDetails!.email!.replaceAll("@gmail.com", "");
    String firstLetter = userName.substring(0, 1).toUpperCase();

   await SharedPreferencesHelper.saveName(userDetails.displayName ?? "");
await SharedPreferencesHelper.saveEmail(userDetails.email ?? "");
await SharedPreferencesHelper.saveImage(userDetails.photoURL ?? "");
await SharedPreferencesHelper.saveId(userDetails.uid);
await SharedPreferencesHelper.saveUserName(userDetails.displayName ?? "");


    if (result != null) {
      Map<String, dynamic> userInfoMap = {
        "Name": userDetails!.displayName,
        "Email": userDetails.email,
        "Image": userDetails.photoURL,
        "Id": userDetails.uid,
        "userName": userName.toUpperCase(),
        "SearchKey": firstLetter
      };

      await DatabaseMethods().addUser(userInfoMap, userDetails.uid);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text("Registered  Successfully!",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold))));
    }
  }
}
