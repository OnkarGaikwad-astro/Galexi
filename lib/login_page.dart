import 'dart:convert';

import 'package:Galexi/essentials/colours.dart';
import 'package:Galexi/home_page.dart';
import 'package:Galexi/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

DateTime startTime = DateTime.now();

TextEditingController bio_text = TextEditingController();

class LoginPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const LoginPage({super.key, required this.toggleTheme});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  
///// navigator  //////
///
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(toggleTheme: widget.toggleTheme),
          ),
        );
      }
    });
  }


  //////  Save user info  //////

  Future<void> save_user(String bio) async {
    final token = await FirebaseMessaging.instance.getToken();
    final response = await http.post(
      Uri.parse(master_url + "save_user"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": await FirebaseAuth.instance.currentUser?.email,
        "name": await FirebaseAuth.instance.currentUser?.displayName,
        "fcm_token": token,
        "bio": bio,
        "profile_pic": await FirebaseAuth.instance.currentUser?.photoURL,
        "phone_no": await FirebaseAuth.instance.currentUser?.phoneNumber,
      }),
    );
    print(response.body);
    print("phone number:${FirebaseAuth.instance.currentUser?.phoneNumber}");
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 100),
            Row(
              children: [
                SizedBox(width: 40),
                SizedBox(
                  child: Text(
                    "Welcome to ",
                    style: TextStyle(
                      color: Color(0xFFD4E4FF),
                      fontSize: 20,
                      fontFamily: "times new roman",
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              child: Text(
                "Galex!",
                style: TextStyle(
                  color: kIcon,
                  fontFamily: "times new roman",
                  fontWeight: FontWeight.w200,
                  fontSize: 30,
                  letterSpacing: 20,
                  shadows: [
                    Shadow(
                      color: const Color.fromARGB(124, 255, 255, 255),
                      offset: Offset(3, 3),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: LottieBuilder.asset(
                "assets/lotties/hello.json",
                height: 250,
              ),
            ),
            SizedBox(
              height: FirebaseAuth.instance.currentUser == null ? 75 : 15,
            ),
            FirebaseAuth.instance.currentUser == null
                ? SizedBox(
                    width: 310,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        final user = await signInWithGoogle();
                        if (user != null) {
                          setState(() {});
                        }
                        ;
                      },
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/images/google_logo_cloud.png",
                            height: 50,
                          ),
                          SizedBox(width: 20),
                          Text(
                            "Sign in with Google",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 74, 241, 233),
                              fontFamily: "times new roman",
                              letterSpacing: 2,
                              wordSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: const Color.fromARGB(255, 0, 255, 213),
                                  offset: Offset(2, 2),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    width: 100,
                    height: 100,
                    child: Lottie.asset(
                      "assets/lotties/check_ok.json",
                      repeat: true,
                    ),
                  ),
            SizedBox(height: 40),
            FirebaseAuth.instance.currentUser == null
                ? SizedBox.shrink()
                : SizedBox(
                    height: 60,
                    width: 350,
                    child: TextField(
                      controller: bio_text,
                      cursorColor: Colors.teal,
                      decoration: InputDecoration(
                        hint: Text(
                          "🚀  Share your cosmic self . . .",
                          style: TextStyle(
                            fontFamily: "times new roman",
                            letterSpacing: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(46, 158, 158, 158),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: (Colors.white)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: (Colors.white)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: (Colors.white)),
                        ),
                      ),
                    ),
                  ),

            SizedBox(height: 20),
             FirebaseAuth.instance.currentUser == null? SizedBox.shrink():SizedBox(
              height: 40,
              width: 100,
              child:OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: kInputBackground,
                        padding: EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: kAccentVariant, width: 200),
                          borderRadius: BorderRadiusGeometry.circular(10),
                        ),
                      ),
                      onPressed: () {
                        save_user(bio_text.text);
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MyHomePage(toggleTheme: widget.toggleTheme),
                            ),
                          );
                      },
                      child: Text(
                        "Done",
                        style: TextStyle(
                          fontFamily: "times new roman",
                          color: const Color.fromARGB(255, 3, 198, 179),
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 20),
            SizedBox(
              child: Text(
                "Across Space 🚀 & Time",
                style: TextStyle(
                  fontFamily: "times new roman",
                  shadows: [
                    Shadow(
                      color: const Color.fromARGB(124, 255, 255, 255),
                      offset: Offset(2, 2),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

/////////  signin   //////
///
Future<UserCredential?> signInWithGoogle() async {
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  final googleAuth = await googleUser!.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  return await FirebaseAuth.instance.signInWithCredential(credential);
}
