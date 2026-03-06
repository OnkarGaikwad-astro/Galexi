import 'dart:convert';

import 'package:Aera/essentials/colours.dart';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/home_page.dart';
import 'package:Aera/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>MyHomePage(toggleTheme: widget.toggleTheme),
          ),
        );
      }
    });
  }


  void showSignin(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(

        backgroundColor: kTextHint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 150,
          width: 100,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            child: Column(
              children: [
                 SizedBox(
                  height: 95,
                  child: Center(
                  child: LottieBuilder.asset(
                    "assets/lotties/Loading_Animation_blue.json",
                  ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(text, style: GoogleFonts.josefinSans(fontSize: 15)),
                  ],
                ),
               
              ],
            ),
          ),
        ),
      ),
    );
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
                    style: GoogleFonts.josefinSans(
                      color: Color(0xFFD4E4FF),
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              child: Text(
                "Aera",
                style: GoogleFonts.orbitron(
                  color: kIcon,
                  fontWeight: FontWeight.w300,
                  fontSize: 30,
                  letterSpacing: 15,
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
            SizedBox(height: 60),
            Center(
              child: LottieBuilder.asset(
                "assets/lotties/Welcome__1.json",
                height: 250,
              ),
            ),
            SizedBox(
              height: FirebaseAuth.instance.currentUser == null ? 155 : 15,
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
                        showSignin(context, "   Signing In . . .");
                        final user = await signInWithGoogle();
                        if (user != null) {
                          Navigator.pop(context);
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
                            style: GoogleFonts.josefinSans(
                              color: const Color.fromARGB(255, 74, 241, 233),
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
                : SizedBox.shrink(),
            SizedBox(height: 30),
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
                          style: GoogleFonts.montaga(
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
                          borderRadius: BorderRadiusGeometry.circular(15),
                        ),
                      ),
                      onPressed: () {
                        chatApi.saveUser(bio_text.text);
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
                        style: GoogleFonts.montaga(
                          color: const Color.fromARGB(255, 3, 198, 179),
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 20),
            SizedBox(
              child: Text(
                "Across Space 🚀 & Time",
                style: GoogleFonts.exo2(
                  // fontFamily: "times new roman",
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
            SizedBox(height: 25,),
            Align(alignment: Alignment.bottomRight,child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Made with ❤️ By Onkar",style: GoogleFonts.josefinSans(fontSize: 10),),
            ))
            // SizedBox(height: 100),
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
