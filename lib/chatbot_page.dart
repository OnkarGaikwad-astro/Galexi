import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:Aera/add_contact.dart';
import 'package:Aera/chat_page.dart';
import 'package:Aera/chatbot_page.dart';
import 'package:Aera/essentials/colours.dart';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/main.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool Isdark = true;
late RealtimeChannel presenceChannel;


class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

TextEditingController type_msg = TextEditingController();
bool msg_sent = true;
bool otherUserTyping = false;
String temp_msg = "";

class _ChatbotPageState extends State<ChatbotPage> with WidgetsBindingObserver {
  late RealtimeChannel messageChannel;

  @override
  ///// fetch chat /////
  Map<String, dynamic> chat = <String, dynamic>{
    "message_count": 0,
    "messages": <dynamic>[],
  };

  static final AudioPlayer _player = AudioPlayer();
  static Future<void> playClick() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/happy-pop-3.mp3'), volume: 1.0);
    print("played");
  }

  static Future<void> receivedsound() async {
    await _player.stop(); // avoid overlap
    await _player.play(AssetSource('sounds/receive.mp3'), volume: 1.0);
    print("played");
  }


  Widget typing_indi() {
    if (otherUserTyping) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: 100, maxHeight: 60),
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(0, 255, 255, 255)),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                topLeft: Radius.zero,
                bottomRight: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              // color:Color.fromARGB(50, 255, 255, 255),
            ),
            child: Lottie.asset("assets/lotties/Chat typing indicator.json"),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }


  Future<void> fetch_chat() async {
    final Map<String, dynamic> msg_list = Map<String, dynamic>.from(
      all_msg_list.value,
    );
    final Map<String, dynamic> contacts = Map<String, dynamic>.from(
      all_contacts.value,
    );
    final dynamic result = msg_list["chats"].firstWhere(
      (c) => c["contact_id"] == "chatbot",
      orElse: () => <String, dynamic>{},
    );
    if (result == null) {
      chat = {"message_count": 0, "messages": []};
    } else {
      chat = Map<String, dynamic>.from(result);
    }
    setState(() {});
  }

  ///////   send message   ////
  Future<void> send_message(String msg) async {
    
    if (msg == "") return;
    otherUserTyping = true;
    gemini(msg);
    final email = await FirebaseAuth.instance.currentUser?.email;
    await chatApi.addMessageFast(email!, "chatbot", msg);
    
    await all_chats_list();
    user_contact();
    playClick();
    print("🚀🚀🚀🚀 msg sent");
  }

  ///// sender_last_seen  /////

  ////////  chat_list  ///////
  Future<void> all_chats_list() async {
    // msg_sent = true;
    final email = FirebaseAuth.instance.currentUser?.email;
    all_msg_list.value = await chatApi.getAllChatsFormatted(email!);
    final box = Hive.box('cache');
    await box.put('all_msg_list', all_msg_list.value);
    setState(() {});
    await fetch_chat();
    msg_sent = true;
    setState(() {});
  }

  String buildChatId(String a, String b) {
    final pair = [a, b]..sort();
    return pair.join("__");
  }

  /// init state  ////
  @override
  void initState() {
    noti = true;
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final myUserId = FirebaseAuth.instance.currentUser!.email!;
    final chatId = buildChatId(myUserId, "chatbot");

    //////   messages realtime  ////
    messageChannel = Supabase.instance.client
        .channel('messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: chatId,
          ),
          callback: (payload) {
            print("🚀🚀🚀🚀🚀🚀🚀 NEW MESSAGE REALTIME");
            final newMsg = payload.newRecord;
            print("new msg $newMsg");
            setState(() {
              
              all_chats_list();
            });

            if (newMsg == null) return;
            if (payload.eventType == PostgresChangeEvent.delete) return;
            if (newMsg["sender_id"] != myUserId) {
              print("📸📸📸 ");
              
              setState(() {
                otherUserTyping = false;
              });
              receivedsound();
            }
            if (newMsg["sender_id"] == myUserId) {
              print("object🚀 ");
             playClick();
            }
          },
        )
        .subscribe();

    Isdark = Hive.box("isdark").get("isDark");
    fetch_chat();
    WidgetsBinding.instance.addObserver(this);
    all_chats_list();
  }

  // ///  refresh msgs when app resumes from home /////

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {}
  }

  /////////

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: true, // allow back navigation
        onPopInvoked: (didPop) {
          if (didPop) {
            noti = false;
            print("🚀DEVICE BACK BUTTON PRESSED");
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            automaticallyImplyLeading: true,
            leading: IconButton(
              onPressed: () async {
                HapticFeedback.selectionClick();
                noti = false;
                msg_sent = true;
                setState(() {});
                user_contact();
                Navigator.pop(context);
                setState(() {});
              },
              icon: Icon(Icons.arrow_back_ios_new_rounded),
            ),
            leadingWidth: 30,
            title: ValueListenableBuilder(
              valueListenable: all_contacts,
              builder: (_, value, _) {
                final contacts = value;
                return SizedBox(
                  width: 270,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Hero(
                          tag: "chatbot",
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            height: 40,
                            width: 40,
                            child: Padding(
                              padding: EdgeInsetsGeometry.all(2),
                              child: Image.asset(
                                "assets/images/ai.png",
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 210,
                        child: Column(
                          children: [
                            Text(
                              style: GoogleFonts.josefinSans(
                                fontSize: 25,
                                color: Isdark
                                    ? const Color.fromARGB(188, 255, 255, 255)
                                    : Colors.black,
                              ),
                              "Aurex!",
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isOnline
                                ? Text(
                                    'Online',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              PopupMenuButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(15),
                  side: BorderSide(
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                enabled: true,
                popUpAnimationStyle: AnimationStyle(
                  duration: Duration(milliseconds: 100),
                ),

                menuPadding: EdgeInsets.all(1),
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
            backgroundColor: Isdark ? kSentMessage : kTextHint,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount:
                          (chat["message_count"] == null ||
                              chat["message_count"] == 0)
                          ? 1
                          : chat["message_count"],
                      itemBuilder: (context, index) {
                        if (chat["message_count"] == null) {
                          return Center(child: SizedBox.shrink());
                        }
                        if (chat["message_count"] == 0) {
                          return SizedBox.shrink();
                        }
                        int realIndex = (chat["message_count"] - 1) - index;
                        if (chat["messages"][realIndex]["msg"] == "")
                          return SizedBox.shrink();
                        return chat["messages"][realIndex]["user_sent"] == "no"
                            ? recieved_msg(realIndex)
                            : sended_msg(realIndex);
                      },
                    ),
                  ),
                  !msg_sent
                      ? (temp_msg != "" ? temp_sended_msg() : SizedBox.shrink())
                      : SizedBox.shrink(),
                  typing_indi(),
                  SizedBox(height: 65),
                ],
              ),
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                height: 50,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                            HapticFeedback.selectionClick();
                            msg_sent = false;
                            setState(() {});
                            final msg = type_msg.text;
                            type_msg.text = "";
                            // gemini(msg);
                            await send_message(msg);
                            temp_msg = "";
                          },
                          controller: type_msg,
                          cursorColor: Colors.teal,
                          decoration: InputDecoration(
                            hint: Padding(
                              padding: const EdgeInsets.only(
                                top: 20,
                                bottom: 7,
                              ),
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
                                color: (Isdark
                                    ? const Color.fromARGB(255, 255, 255, 255)
                                    : Colors.black),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: (Isdark ? Colors.white : Colors.black),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: (Isdark
                                    ? const Color.fromARGB(255, 121, 120, 120)
                                    : Colors.black),
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
                            HapticFeedback.selectionClick();
                            msg_sent = false;
                            setState(() {});
                            final msg = type_msg.text;
                            type_msg.text = "";

                            if (msg != "") {
                              // gemini(msg);
                              await send_message(msg);
                            }

                            temp_msg = "";
                            setState(() {});
                          },
                          icon: Icon(Icons.send_rounded, size: 25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /////  mark msg seen ////
  Future<void> mark_msg_seen(String other_user) async {
    print("\nmarking \n");
    final email = await FirebaseAuth.instance.currentUser?.email;
    final a = await chatApi.markLastMsgSeen(email!, other_user);
    print("🚀🚀🚀:${a}");
    await user_contacts();
  }

  Future<void> user_contacts() async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    final a = await chatApi.getUserContacts(email!);
    all_contacts.value = a;
    final box = Hive.box('cache');
    box.put('all_contacts', all_contacts.value);
    setState(() {});
  }

  ///////  recieved message widget ///////
  Widget recieved_msg(int no) {
    return GestureDetector(
      onLongPressStart: (details) {
        HapticFeedback.selectionClick();
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
            100,
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
            PopupMenuItem(
              value: "Copy",
              child: Row(
                children: [
                  Icon(
                    Icons.content_copy_outlined,
                    color: const Color.fromARGB(255, 8, 242, 219),
                  ),
                  SizedBox(width: 10),
                  Text("Copy Text"),
                ],
              ),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  SizedBox(width: 30),
                  Text(
                    "${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[0]} \n ${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0]} ",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontFamily: "times new roman",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).then((value) {
          if (value == "delete") {
            delete_msg(chat["messages"][no]["conversation_id"]);
          }
          ;
          if (value == "Copy") {
            Clipboard.setData(ClipboardData(text: chat["messages"][no]["msg"]));
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
                style: GoogleFonts.josefinSans(
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
        HapticFeedback.selectionClick();
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
            PopupMenuItem(
              value: "Copy",
              child: Row(
                children: [
                  Icon(
                    Icons.content_copy_outlined,
                    color: const Color.fromARGB(255, 8, 242, 219),
                  ),
                  SizedBox(width: 10),
                  Text("Copy Text"),
                ],
              ),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  SizedBox(width: 30),
                  Text(
                    "${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[0]} \n ${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0]} ",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontFamily: "times new roman",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).then((value) {
          if (value == "delete") {
            delete_msg(chat["messages"][no]["conversation_id"]);
          }
          ;
          if (value == "Copy") {
            Clipboard.setData(ClipboardData(text: chat["messages"][no]["msg"]));
          }
          ;
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
                style: GoogleFonts.josefinSans(color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //////   temp_sended_mgs  //////
  Widget temp_sended_msg() {
    if (temp_msg != null) {
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
              color: Color(0xFF5BB9A8),
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
    } else {
      return SizedBox.shrink();
    }
  }

  ////////   clear_chat ///////
  Future<void> clear_chat() async {
    final contacts = all_contacts.value;
    final email = FirebaseAuth.instance.currentUser?.email;
    await chatApi.clearChat(email!, "chatbot");
    user_contact();
    await all_chats_list();
    setState(() {});
    print("🚀🚀🚀 cleared chat line 1230 ");
  }

  ////// delete message  //////
  Future<void> delete_msg(int convo_id) async {
    final email = FirebaseAuth.instance.currentUser!.email!;
    await chatApi.deleteSingleMessage(email, "chatbot", convo_id);
    user_contact();
    await all_chats_list();
    HapticFeedback.heavyImpact();
    print("deleted ");
  }

  /////  refresh contacts   //////
  Future<void> user_contact() async {
    await appKey.currentState?.user_contacts();
  }

  Future<void> gemini(String prompt) async {
    String apiKey = "AIzaSyCBT4vi-x_uTgZ7TiM3cQ-Xxmi-QcxGcos";
    print("asking🚀🚀 ");
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    prompt +
                    "imagine u as an ai build by astro and named Aurex of u and u are an commercial ai mode build for an app named aera , dont always mention all info about u just give answers which was asked and must have frendly tone dont give long info give just main info ",
              },
            ],
          },
        ],
      }),
    );
    String res = "ERROR";
    if (response.statusCode == 200) {
      res = jsonDecode(
        response.body,
      )["candidates"][0]["content"]["parts"][0]["text"];
    }
    send_response(res);
    setState(() {});
  }

  Future<void> send_response(String msg) async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    await chatApi.addMessageFast("chatbot", email!, msg);
    await all_chats_list();
    user_contact();
    print("🚀🚀🚀🚀 response sent");
  }
}
