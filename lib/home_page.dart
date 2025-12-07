import 'package:Galexi/chat_page.dart';
import 'package:Galexi/essentials/colours.dart';
import 'package:Galexi/login_page.dart';
import 'package:Galexi/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';

Color chat_color = const Color.fromARGB(133, 16, 37, 79);
TextEditingController search_chat = TextEditingController();

class MyHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const MyHomePage({super.key, required this.toggleTheme});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /////////    refresh    ///////

  Future<void> _refresh() async {
    Future.delayed(Duration(seconds: 1));
    setState(() {});
  }

  ////// logout //////
  ///
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  // ////   chatlist widget
  Widget chat_list(int num) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          splashColor: Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(200, 255, 255, 255)
              : const Color.fromARGB(189, 0, 0, 0),
          borderRadius: BorderRadius.circular(15),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatPage()),
            );
          },

          child: Hero(
            tag:"prof_page",
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: chat_color,
              ),
              width: double.infinity,
              height: 60,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CircleAvatar(
                      maxRadius: 23,
                      backgroundImage: NetworkImage(
                        contacts["contacts"][num]["profile_pic"],
                      ),
                    ),
                  ),
                  SizedBox(width: 9),
                  SizedBox(
                    width: 230,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 300,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 210,
                                  child: Text(
                                    contacts["contacts"][num]["name"],
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: "times new roman",
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(width: 4),
                            SizedBox(
                              width: 210,
                              child: Text(
                                overflow: TextOverflow.ellipsis,
                                contacts["contacts"][num]["last_message"],
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: const Color.fromARGB(255, 198, 196, 196),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    contacts["contacts"][num]["last_message_time"],
                    style: TextStyle(
                      fontSize: 8,
                      fontFamily: "times new roman",
                      color: isdark
                          ? Colors.grey
                          : const Color.fromARGB(255, 72, 71, 71),
                    ),
                  ),
                  SizedBox(width: 7,),
                  contacts["contacts"][num]["msg_seen"]!="seen"?Text("🚀",style: TextStyle(fontSize: 14)):SizedBox.shrink()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /////// user contacts //////

  Future<void> user_contacts() async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    final response = await http.get(
      Uri.parse(master_url + "user_contacts/${email}"),
    );
    contacts = jsonDecode(response.body);
    print(contacts);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (FirebaseAuth.instance.currentUser == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(toggleTheme: widget.toggleTheme),
          ),
        );
      }
    });
    user_contacts();
  }

  @override
  Widget build(BuildContext context) {
    final isdark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      drawerEdgeDragWidth: 100,
      drawer: SafeArea(
        left: true,
        right: true,
        bottom: true,
        child: Drawer(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  user_contacts();
                },
                child: Text("contacts"),
              ),

              ElevatedButton(
                onPressed: () async {
                  String? token = await FirebaseMessaging.instance.getToken();
                  print("FCM Token: $token");
                },
                child: Text("Token"),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () async {
            await signOut();
            if (FirebaseAuth.instance.currentUser == null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LoginPage(toggleTheme: widget.toggleTheme),
                ),
              );
            }
          },
          icon: Icon(Icons.logout),
        ),
        backgroundColor: isdark ? kSentMessage : kTextHint,
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: widget.toggleTheme,
            icon: isdark
                ? Icon(Icons.dark_mode_outlined, size: 23)
                : Icon(Icons.light_mode_outlined),
          ),
        ],
        title: Text(
          "Galexi",
          style: TextStyle(
            fontFamily: "times new roman",
            letterSpacing: 17,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 50,
                child: TextField(
                  controller: search_chat,

                  onChanged: (value) {
                    print(search_chat.text);
                  },
                  onSubmitted: (value) {
                    print(search_chat.text);
                  },

                  cursorColor: isdark
                      ? const Color.fromARGB(255, 122, 218, 238)
                      : kPrimaryVariant,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 25),
                    hint: Text(
                      "Find a star to chat with.....",
                      style: TextStyle(
                        letterSpacing: 2,
                        fontFamily: "times new roman",
                      ),
                    ),
                    fillColor: const Color.fromARGB(104, 158, 158, 158),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: kAccentVariant,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: kAccentVariant,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: kAccentVariant,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: contacts["contact_count"] == null
                    ? Lottie.asset("assets/lotties/rocket.json")
                    : Column(
                        children: List.generate(contacts["contact_count"], (
                          index,
                        ) {
                          return chat_list(index);
                        }),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
