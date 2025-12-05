import 'package:aurex_messenger/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MyHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const MyHomePage({super.key, required this.toggleTheme});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {



// logout
  Future<void> signOut() async {
  await GoogleSignIn().signOut();   
  await FirebaseAuth.instance.signOut();  
}



@override
  void initState() {
    super.initState();
    Future.microtask(() {
      if(FirebaseAuth.instance.currentUser==null){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage(toggleTheme: widget.toggleTheme),));
        }
    },);
  }

  @override
  Widget build(BuildContext context) {
    final isdark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      
      appBar: AppBar(leading: IconButton(onPressed: ()async {
        await signOut();
        if(FirebaseAuth.instance.currentUser==null){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage(toggleTheme: widget.toggleTheme),));
        }
      }, icon: Icon(Icons.logout)),
        backgroundColor: const Color.fromARGB(255, 26, 181, 166),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: widget.toggleTheme,
            icon: isdark
                ? Icon(Icons.dark_mode_outlined)
                : Icon(Icons.light_mode_outlined),
          )
        ],
        title: Text("Galexi",style: TextStyle(fontFamily: "times new roman",letterSpacing: 17,fontSize: 20),),
      ),
      body: ElevatedButton(onPressed: () async{
        String? token = await FirebaseMessaging.instance.getToken();
      print("FCM Token: $token");
      }, child: Text("Token")),
    );
  }
}

// Future<void> fetchPosts() async {
//   final url_all = Uri.parse(url+"all");
//   final response = await http.get(url_all);

//   if (response.statusCode == 200) {
//     data = jsonDecode(response.body);
//   } else {
//     throw Exception("Failed to load data");
//   }
// }

