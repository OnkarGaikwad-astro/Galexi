import 'package:Galexi/add_contact.dart';
import 'package:Galexi/chat_page.dart';
import 'package:Galexi/chatbot_page.dart';
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

class MyHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const MyHomePage({super.key, required this.toggleTheme});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /////////    refresh    ///////

  Future<void> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    await user_contacts();
    setState(() {});
  }

  ////// logout //////

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  ///////  mark_msg_seen /////

  Future<void> mark_msg_seen(String other_user) async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    final response = await http.patch(
      Uri.parse(master_url + "mark_msg_seen/${email}/${other_user}"),
    );
    await user_contacts();
    setState(() {});
  }

  //////   chatlist widget  //////
  Widget chat_list(int num) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          splashColor: Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(200, 255, 255, 255)
              : const Color.fromARGB(189, 0, 0, 0),
          borderRadius: BorderRadius.circular(15),

          onTap: () async {
            mark_msg_seen(contacts["contacts"][num]["id"]);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(index: num, isdark: isdark),
              ),
            );
          },

          child: Hero(
            tag: "prof_page",
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
                      backgroundColor: Colors.white,
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
                                  color: const Color.fromARGB(
                                    255,
                                    198,
                                    196,
                                    196,
                                  ),
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
                  SizedBox(width: 7),
                  contacts["contacts"][num]["msg_seen"] != "seen"
                      ? Text("🚀", style: TextStyle(fontSize: 14))
                      : SizedBox.shrink(),
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
    contacts = contacts;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    contacts = contacts;
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
      floatingActionButton: FloatingActionButton(
        elevation: 30,
        backgroundColor: kSentMessage,
        foregroundColor: const Color.fromARGB(255, 171, 195, 229),
        child: Icon(Icons.person_add_alt_1),
        onPressed: () {
          print("Onkar");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddContact()),
          );
        },
      ),
      // drawerEdgeDragWidth: 100,
      // drawer: SafeArea(
      //   left: true,
      //   right: true,
      //   bottom: true,
      //   child: Drawer(
      //     child: Column(
      //       children: [
      //         ElevatedButton(
      //           onPressed: () async {
      //             user_contacts();
      //           },
      //           child: Text("contacts"),
      //         ),

      //         ElevatedButton(
      //           onPressed: () async {
      //             String? token = await FirebaseMessaging.instance.getToken();
      //             print("FCM Token: $token");
      //           },
      //           child: Text("Token"),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
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
        actions: [InkWell(borderRadius: BorderRadius.circular(17),onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatbotPage(),));
        },child: CircleAvatar(maxRadius: 15,backgroundColor:  isdark ? const Color.fromARGB(78, 25, 50, 98) : kTextHint,backgroundImage: AssetImage("assets/images/ai.png"),)),
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
        elevation: 10,
        color: kAccentVariant,
        onRefresh: _refresh,
        child:
            contacts["contact_count"] == null || contacts["contact_count"] == 0
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  Center(child: Lottie.asset("assets/lotties/rocket.json")),
                ],
              )
            : ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: contacts["contact_count"],
                itemBuilder: (context, index) {
                  return chat_list(index);
                },
              ),
      ),
    );
  }
}
