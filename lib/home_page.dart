import 'package:Aera/add_contact.dart';
import 'package:Aera/chat_page.dart';
import 'package:Aera/chatbot_page.dart';
import 'package:Aera/essentials/colours.dart';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/essentials/functions.dart';
import 'package:Aera/login_page.dart';
import 'package:Aera/main.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:Aera/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';

Color chat_color = const Color.fromARGB(133, 16, 37, 79);
bool isdark = true;

class MyHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const MyHomePage({super.key, required this.toggleTheme});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /////////    refresh    ///////

  Future<void> _refresh() async {
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
    final a = await chatApi.markLastMsgSeen(email!, other_user);
    await user_contacts();
    setState(() {});
  }

  //////   chatlist widget  //////
  Widget chat_list(int num) {
    return Center(
      child: ValueListenableBuilder(
        valueListenable: all_contacts,
        builder: (_, value, _) {
          final contacts = value;
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: GestureDetector(
              onLongPressStart: (LongPressStartDetails details) async {
                HapticFeedback.lightImpact();
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset position = details.globalPosition;
                const double menuWidth = 180;
                const double horizontalGap = 12;
                double left = position.dx + horizontalGap;
                double top = position.dy;
                await showMenu(
                  context: context,
                  elevation: 100,
                  shadowColor: kAccentVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  popUpAnimationStyle: const AnimationStyle(
                    duration: Duration(milliseconds: 200),
                    reverseDuration: Duration(milliseconds: 100),
                  ),
                  menuPadding: const EdgeInsets.all(2),

                  position: RelativeRect.fromLTRB(
                    left,
                    top,
                    overlay.size.width - left - menuWidth,
                    overlay.size.height - top,
                  ),

                  items: const [
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, color: Colors.red),
                          SizedBox(width: 10),
                          Text("Delete"),
                        ],
                      ),
                    ),
                  ],
                ).then((value) async {
                  if (value == "delete") {
                    final email =
                        await FirebaseAuth.instance.currentUser?.email;
                    await chatApi.removeContactAndClearChat(
                      email!,
                      contacts["contacts"][num]["id"],
                    );
                    await user_contacts();
                    print("removed");
                    setState(() {});
                  }
                });
              },

              onTap: () async {
                HapticFeedback.selectionClick();
                mark_msg_seen(contacts["contacts"][num]["id"]);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatPage(ID: contacts["contacts"][num]["id"]),
                  ),
                );
              },

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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.vibrate();
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                child: Builder(
                                  builder: (context) {
                                    const double imageSize = 300;
                                    final double dpr = MediaQuery.of(
                                      context,
                                    ).devicePixelRatio;

                                    String highQualityUrl(String url) {
                                      return url.replaceAll(
                                        RegExp(r's\d+-c'),
                                        's800-c',
                                      );
                                    }

                                    return Container(
                                      height: 330,
                                      padding: const EdgeInsets.all(2),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Hero(
                                            tag:
                                                contacts["contacts"][num]["name"],
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: RepaintBoundary(
                                                child: CachedNetworkImage(
                                                  imageUrl: highQualityUrl(
                                                    contacts["contacts"][num]["profile_pic"],
                                                  ),
                                                  width: imageSize,
                                                  height: imageSize,
                                                  fit: BoxFit.contain,
                                                  filterQuality:
                                                      FilterQuality.high,
                                                  memCacheWidth:
                                                      (imageSize * dpr).round(),
                                                  memCacheHeight:
                                                      (imageSize * dpr).round(),
                                                  fadeInDuration: Duration.zero,
                                                  fadeOutDuration:
                                                      Duration.zero,
                                                  placeholder: (context, url) =>
                                                      const SizedBox(
                                                        height: 300,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                      ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const Icon(
                                                            Icons.broken_image,
                                                            size: 40,
                                                          ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            contacts["contacts"][num]["name"],
                                            style: const TextStyle(
                                              fontFamily: "times new roman",
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                        child: Hero(
                          tag: contacts["contacts"][num]["name"],
                          child: Container(
                            height: 44,
                            width: 44,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl:
                                    contacts["contacts"][num]["profile_pic"],
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,

                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
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

                                  all_contacts.value["contacts"][num]["last_message"]
                                          .contains(SECRET_MARKER)
                                      ? " ◯ Image"
                                      : all_contacts.value["contacts"][num]["last_message"],
                                  style: TextStyle(
                                    fontFamily: "times new roman",
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
                      all_contacts.value["contacts"][num]["last_message_time"],
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
          );
        },
      ),
    );
  }

  /////// user contacts //////

  Future<void> user_contacts() async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    final a = await chatApi.getUserContacts(email!);
    all_contacts.value = a;
    final box = Hive.box('cache');
    box.put('all_contacts', all_contacts.value);

    setState(() {});
  }

  static final AudioPlayer _player = AudioPlayer();
  static Future<void> playClick() async {
    await _player.stop(); // avoid overlap
    await _player.play(AssetSource('sounds/happy-pop-3.mp3'), volume: 1.0);
    print("played");
  }

  @override
  void initState() {
    super.initState();
    isdark = Hive.box("isdark").get("isDark") ?? true;
    Hive.box("isdark").put("isDark", isdark);
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            widget.toggleTheme();
          },
          icon: isdark
              ? Icon(Icons.dark_mode_outlined, size: 25)
              : Icon(Icons.light_mode_outlined),
        ),
        backgroundColor: isdark ? kSentMessage : kTextHint,
        centerTitle: true,
        elevation: 2,
        actions: [
          // InkWell(
          //   borderRadius: BorderRadius.circular(17),
          //   onTap: () async {
          //     // Navigator.push(
          //     //   context,
          //     //   MaterialPageRoute(
          //     //     builder: (context) {
          //     //       return ChatbotPage();
          //     //     },
          //     //   ),
          //     // );

          //     // final email = await FirebaseAuth.instance.currentUser?.email;
          //     // chatApi.addMessageFast("onkar.gaikwad@iitgn.ac.in",email!,"hi");
          //     // print("\n");
          //     // print("📷📷📷 done  ${a}");
          //     print(all_contacts.value);
          //     // playClick();
          //     print("done");
          //     // print("\n");
          //     // final chat = all_msg_list.value;
          //     // print("🚀 ${chat}");
          //     // print("\n");
          //   },
          //   child: CircleAvatar(
          //     maxRadius: 15,
          //     backgroundColor: isdark
          //         ? const Color.fromARGB(78, 25, 50, 98)
          //         : kTextHint,
          //     backgroundImage: AssetImage("assets/images/ai.png"),
          //   ),
          // ),
          SizedBox(width: 15),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
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
                position: RelativeRect.fromLTRB(100, 80, 0, 0),
                menuPadding: EdgeInsets.all(2),
                items: [
                  PopupMenuItem(
                    value: "logout",
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Logout"),
                      ],
                    ),
                  ),
                ],
              ).then((value) async {
                if (value == "logout") {
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
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                height: 43,
                width: 43,
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(13),
                  child: CachedNetworkImage(
                    filterQuality: FilterQuality.high,
                    imageUrl: FirebaseAuth.instance.currentUser!.photoURL!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          padding: EdgeInsets.all(5),
                          color: Colors.black,
                          constraints: BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image),
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                  ),
                  // child: Image.network(contacts["contacts"][num]["profile_pic"]),
                ),
              ),
            ),
          ),
        ],
        title: Text(
          "Aera",
          style: TextStyle(
            fontFamily: "times new roman",
            letterSpacing: 17,
            fontSize: 20,
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: all_contacts,
        builder: (_, value, _) {
          final contacts = value;
          return RefreshIndicator(
            elevation: 10,
            color: kAccentVariant,
            onRefresh: _refresh,
            child:
                contacts["contact_count"] == null ||
                    contacts["contact_count"] == 0
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
          );
        },
      ),
    );
  }
}
