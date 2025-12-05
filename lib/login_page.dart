import 'package:aurex_messenger/essentials/colours.dart';
import 'package:aurex_messenger/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';

// TextEditingController Emailcontroller = TextEditingController();
// TextEditingController Passwordcontroller = TextEditingController();

class LoginPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const LoginPage({super.key, required this.toggleTheme});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // navigator
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

            SizedBox(height: 55),

            SizedBox(
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
                    print("Name: ${user.user?.displayName}");
                    print("Email: ${user.user?.email}");
                    print("Photo: ${user.user?.photoURL}");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MyHomePage(toggleTheme: widget.toggleTheme),
                      ),
                    );
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
            ),
            SizedBox(height: 130),
            SizedBox(
              child: Text(
                "Across Space 🚀 & Time",
                style: TextStyle(fontFamily: "times new roman",shadows: [
                    Shadow(
                      color: const Color.fromARGB(124, 255, 255, 255),
                      offset: Offset(2, 2),
                      blurRadius: 30,
                    ),
                  ],),
              ),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// signin
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
