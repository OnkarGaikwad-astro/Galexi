import 'dart:convert';

import 'package:Galexi/essentials/colours.dart';
import 'package:Galexi/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class ChatPage extends StatefulWidget {
  final dynamic index;
  final dynamic isdark;
  const ChatPage({super.key, required this.index, required this.isdark});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

TextEditingController type_msg = TextEditingController();
String sender_last_seen = "";
bool msg_sent = true;
String temp_msg = "";

class _ChatPageState extends State<ChatPage> {
  @override
  ///// fetch chat /////
  Map<String, dynamic> chat = {};

  Future<void> fetch_chat() async {
    var result = msg_list["chats"].firstWhere(
      (c) => c["contact_id"] == contacts["contacts"][widget.index]["id"],
      orElse: () => null,
    );
    if (result == null) {
      chat = {"message_count": 0, "messages": []};
    } else {
      chat = result;
    }
    setState(() {});
  }

  ///////   send message   ////
  Future<void> send_message(String msg) async {
    final response = await http.post(
      Uri.parse(master_url + "add_message"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "sender_id": await FirebaseAuth.instance.currentUser?.email,
        "receiver_id": contacts["contacts"][widget.index]["id"],
        "msg": msg,
      }),
    );
    print(response.body);
  }

  ///// sender_last_seen  /////

  Future<void> last_seen() async {
    print("last_seen_fetch_start");
    final response = await http.get(
      Uri.parse(
        master_url + "last_seen/${contacts["contacts"][widget.index]["id"]}",
      ),
      headers: {"Content-Type": "application/json"},
    );
    sender_last_seen = jsonDecode(response.body)["last_seen"].toString();
    setState(() {});
    print("🚀last_seeen_fetched");
    print(jsonDecode(response.body)["last_seen"].toString());
  }

  ////////  chat_list  ///////
  Future<void> all_chats_list() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    final response = await http.get(
      Uri.parse(master_url + "all_chats/${email}"),
      headers: {"Content-Type": "application/json"},
    );
    msg_list = await jsonDecode(response.body);
    print(msg_list);
    await fetch_chat();
    msg_sent = true;
    setState(() {});
  }

  ///
  @override
  void initState() {
    super.initState();
    last_seen();
    fetch_chat();
    all_chats_list();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      last_seen();
      await all_chats_list();
      setState(() {});
      print("🔔 message received");
    });
  }

  ///

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            user_contact();
            Navigator.pop(context);
            setState(() {});
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
        leadingWidth: 30,
        title: SizedBox(
          width: 270,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: CircleAvatar(
                  maxRadius: 19,
                  backgroundImage: NetworkImage(
                    contacts["contacts"][widget.index]["profile_pic"],
                  ),
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 210,
                child: Column(
                  children: [
                    Text(
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "times new roman",
                      ),
                      contacts["contacts"][widget.index]["name"],
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        SizedBox(width: 90),
                        Text(
                          "Last seen at : ",
                          style: TextStyle(fontSize: 7, color: kTextSecondary),
                        ),
                        Text(
                          sender_last_seen,
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton(
            onSelected: (value) async {
              if (value == "clear") {
                await clear_chat();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: "clear", child: Text("Clear Chat")),
            ],
          ),
        ],
        backgroundColor: isdark ? kSentMessage : kTextHint,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 20),
              Expanded(
                child: ListView(
                  reverse: false,
                  children:
                      (chat["message_count"] == null ||
                          chat["message_count"] == 0)
                      ? [Lottie.asset("assets/lotties/paperplane.json")]
                      : List.generate(
                          chat["message_count"],
                          (index) => (index != 0)
                              ? (chat["messages"][index]["user_sent"] == "no"
                                    ? recieved_msg(index)
                                    : sended_msg(index))
                              : SizedBox.shrink(),
                        ),
                ),
              ),
              !msg_sent
                  ? (temp_msg != null ? temp_sended_msg() : SizedBox.shrink())
                  : SizedBox.shrink(),
              SizedBox(height: 60),
            ],
          ),
          Positioned(
            bottom: 15,
            left: 10,
            right: 10,
            height: 50,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  width: 300,
                  height: 50,
                  child: TextField(
                    onChanged: (value) {
                      msg_sent = false;
                      temp_msg = type_msg.text;
                      if (type_msg.text.trim().isEmpty) {
                        msg_sent = true;
                        setState(() {});
                      }
                      setState(() {});
                    },
                    onSubmitted: (value) async {
                      msg_sent = false;
                      setState(() {});
                      final msg = type_msg.text;
                      type_msg.text = "";

                      await send_message(msg);
                      await all_chats_list();
                    },
                    controller: type_msg,
                    cursorColor: Colors.teal,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("🚀", style: TextStyle(fontSize: 17)),
                      ),
                      hint: Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 7),
                        child: Text(
                          "Send across the galaxy . . .",
                          style: TextStyle(
                            fontFamily: "times new roman",
                            letterSpacing: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(46, 158, 158, 158),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: (isdark ? Colors.white : Colors.black),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: (isdark ? Colors.white : Colors.black),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: (isdark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 7),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Color.fromARGB(255, 59, 148, 181),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      msg_sent = false;
                      setState(() {});
                      final msg = type_msg.text;
                      type_msg.text = "";
                      await send_message(msg);
                      await all_chats_list();
                    },
                    icon: Icon(Icons.send_rounded, size: 25),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ///////  recieved message widget ///////
  Widget recieved_msg(int no) {
    return GestureDetector(
      onLongPressStart: (details) {
        showMenu(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(20),
          ),
          popUpAnimationStyle: AnimationStyle(
            duration: Duration(milliseconds: 200),
            reverseDuration: Duration(milliseconds: 100),
          ),
          shadowColor: kAccentVariant,
          elevation: 100,
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            0,
            0,
          ),
          menuPadding: EdgeInsets.all(2),
          items: [
            PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Delete"),
                ],
              ),
            ),
          ],
        ).then((value) {
          if (value == "delete") {
            delete_msg(no);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: 270),
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(0, 255, 255, 255)),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                topLeft: Radius.zero,
                bottomRight: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              color: Color.fromARGB(255, 109, 168, 174),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 3,
                top: 3,
                left: 7,
                right: 7,
              ),
              child: Text(
                chat["messages"][no]["msg"],
                style: TextStyle(
                  fontFamily: "Comic Sans MS",
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //////// sent message widget  ///////
  Widget sended_msg(int no) {
    return GestureDetector(
      onLongPressStart: (details) {
        showMenu(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(20),
          ),
          popUpAnimationStyle: AnimationStyle(
            duration: Duration(milliseconds: 200),
            reverseDuration: Duration(milliseconds: 100),
          ),
          shadowColor: kAccentVariant,
          elevation: 100,
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            0,
            0,
          ),
          menuPadding: EdgeInsets.all(2),
          items: [
            PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Delete"),
                ],
              ),
            ),
          ],
        ).then((value) {
          if (value == "delete") {
            delete_msg(no);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        child: Align(
          alignment: Alignment.topRight,
          child: Container(
            constraints: BoxConstraints(maxWidth: 270),
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(0, 255, 255, 255)),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                topLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
                topRight: Radius.zero,
              ),
              color: Color.fromARGB(255, 130, 158, 190),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 3,
                top: 3,
                left: 7,
                right: 7,
              ),
              child: Text(
                chat["messages"][no]["msg"],
                style: TextStyle(
                  fontFamily: "Comic Sans MS",
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //////   temp_sended_mgs  //////
  Widget temp_sended_msg() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: 270),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(0, 255, 255, 255)),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(15),
              topLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
              topRight: Radius.zero,
            ),
            color: Color.fromARGB(255, 130, 158, 190),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 3,
              top: 3,
              left: 7,
              right: 7,
            ),
            child: Text(
              temp_msg,
              style: TextStyle(
                fontFamily: "Comic Sans MS",
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  ////////   clear_chat ///////
  Future<void> clear_chat() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    final response = await http.delete(
      Uri.parse(
        master_url +
            "clear_chat/${email}/${contacts["contacts"][widget.index]["id"]}",
      ),
      headers: {"Content-Type": "application/json"},
    );
    await all_chats_list();
    await fetch_chat();
    user_contact();
    setState(() {});
    print(response.body);
  }

  ////// delete message  //////
  Future<void> delete_msg(int convo_id) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    final response = await http.delete(
      Uri.parse(
        master_url +
            "delete_message/${email}/${contacts["contacts"][widget.index]["id"]}/${convo_id}",
      ),
      headers: {"Content-Type": "application/json"},
    );
    await all_chats_list();
    await fetch_chat();
    user_contact();
    setState(() {});
    print(response.body);
  }

  /////  refresh contacts   //////
  Future<void> user_contact() async {
    await appKey.currentState?.user_contacts();
  }
}
