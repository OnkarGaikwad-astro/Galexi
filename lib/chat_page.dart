import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:Aera/add_contact.dart';
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
bool isSelecting = false;
List selected_items = [];

int replyid = -1;
bool noti = false;
late RealtimeChannel presenceChannel;
bool isOnline = false;
String your_name = "";
class ChatPage extends StatefulWidget {
  final dynamic ID;
  const ChatPage({super.key, required this.ID});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

TextEditingController type_msg = TextEditingController();
String sender_last_seen = "";
String SECRET_MARKER = '\u{E000}';
bool msg_sent = true;
String temp_msg = "";
String chatId = "";

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late RealtimeChannel typingChannel;
  late RealtimeChannel messageChannel;

  bool isreplying = false;

  @override
  ///// fetch chat /////
  Map<String, dynamic> chat = <String, dynamic>{
    "message_count": 0,
    "messages": <dynamic>[],
  };
  File? selectedImage;
  bool otherUserTyping = false;

  static final AudioPlayer _player = AudioPlayer();
  static Future<void> playClick() async {
    await _player.stop(); // avoid overlap
    await _player.play(AssetSource('sounds/happy-pop-3.mp3'), volume: 1.0);
    print("played");
  }

  static Future<void> receivedsound() async {
    await _player.stop(); // avoid overlap
    await _player.play(AssetSource('sounds/receive.mp3'), volume: 1.0);
    print("played");
  }

  Future<void> fetch_chat() async {
    final Map<String, dynamic> msg_list = Map<String, dynamic>.from(
      all_msg_list.value,
    );
    final Map<String, dynamic> contacts = Map<String, dynamic>.from(
      all_contacts.value,
    );
    final dynamic result = msg_list["chats"].firstWhere(
      (c) =>
          c["chat_id"] ==
          contacts["contacts"][contacts["contacts"].indexWhere(
            (e) => e['chat_id'] == chatId,
          )]["chat_id"],
      orElse: () => <String, dynamic>{},
    );
    if (result == null) {
      chat = {"message_count": 0, "messages": []};
    } else {
      chat = Map<String, dynamic>.from(result);
    }
    setState(() {});
  }


  Future<void> username() async {
      final name = await FirebaseAuth.instance.currentUser!.displayName;
      your_name = name!;
      print(name);
    setState(() {});
  }

  ///////   send message   ////
  Future<void> send_message(String msg, String type) async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    await chatApi.addMessageFast(email!, widget.ID, msg, chatId, type);
    print("📖📖📖📖📖📖📖 ");
    if (msg != "") playClick();
    await all_chats_list();
    user_contact();
    print("🚀🚀🚀🚀 msg sent");
  }

  ///// sender_last_seen  /////

  Future<void> last_seen() async {
    final Map<String, dynamic> contacts = Map<String, dynamic>.from(
      all_contacts.value,
    );
    print("last_seen_fetch_start");
    final response = await chatApi.getLastSeen(widget.ID);
    sender_last_seen = response!;
    setState(() {});
    print("🚀last_seeen_fetched");
    // print(response);
  }

  void listenPresence(String otherUser) {
    presenceChannel = Supabase.instance.client
        .channel('presence:$otherUser')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_presence',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: otherUser,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data == null) return;

            setState(() {
              isOnline = data['is_online'] == true;
            });

            print('🟢 PRESENCE UPDATE → $isOnline');
          },
        )
        .subscribe();
  }

  ////////  chat_list  ///////
  Future<void> all_chats_list() async {
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
    username();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      listenPresence(widget.ID);
    });
    mark_msg_seen(widget.ID);
    final myUserId = FirebaseAuth.instance.currentUser!.email!;
    chatId = buildChatId(myUserId, widget.ID);

    //////  typing indicator  //////
    typingChannel = Supabase.instance.client
        .channel('typing:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'typing_status',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            print("chatid:$chatId");
            print('📖 TYPING..');
            final data = payload.newRecord;
            if (data == null) return;
            if (data['user_id'] == myUserId) return;
            setState(() {
              otherUserTyping = data['is_typing'] == true;
            });
          },
        )
        .subscribe();

    //////   messages realtime  ////
    messageChannel = Supabase.instance.client
        .channel('messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
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
              receivedsound();
            }
          },
        )
        .subscribe();

    Isdark = Hive.box("isdark").get("isDark");
    fetch_chat();
    last_seen();
    WidgetsBinding.instance.addObserver(this);
    all_chats_list();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      last_seen();
      await all_chats_list();
      setState(() {});
      print("🔔 message received");
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    messageChannel.unsubscribe();
    _typingTimer?.cancel();
    typingChannel.unsubscribe();
    presenceChannel.unsubscribe();
    final me = FirebaseAuth.instance.currentUser!.email!;
    final chatId = buildChatId(me, widget.ID);
    Supabase.instance.client
        .from('typing_status')
        .update({'is_typing': false})
        .eq('chat_id', chatId)
        .eq('user_id', me);
    super.dispose();
  }

  // ///  refresh msgs when app resumes from home /////

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      chatApi.setOnline();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      chatApi.setOffline();
    }
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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      print("BAR PRESSED 🚀");
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
                                  // height: 430,
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Hero(
                                        tag:
                                            contacts["contacts"][contacts["contacts"]
                                                .indexWhere(
                                                  (e) => e['id'] == widget.ID,
                                                )]["name"],
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: RepaintBoundary(
                                            child: CachedNetworkImage(
                                              imageUrl: highQualityUrl(
                                                contacts["contacts"][contacts["contacts"]
                                                    .indexWhere(
                                                      (e) =>
                                                          e['id'] == widget.ID,
                                                    )]["profile_pic"],
                                              ),
                                              width: imageSize,
                                              height: imageSize,
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                              memCacheWidth: (imageSize * dpr)
                                                  .round(),
                                              memCacheHeight: (imageSize * dpr)
                                                  .round(),
                                              fadeInDuration: Duration.zero,
                                              fadeOutDuration: Duration.zero,
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
                                      const SizedBox(height: 3),
                                      Text(
                                        contacts["contacts"][contacts["contacts"]
                                            .indexWhere(
                                              (e) => e['id'] == widget.ID,
                                            )]["name"],
                                        style: TextStyle(
                                          fontFamily: "times new roman",
                                          fontSize: 10,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 8,
                                        child: Text(
                                          widget.ID,
                                          style: TextStyle(fontSize: 5),
                                        ),
                                      ),
                                      contacts["contacts"][contacts["contacts"]
                                                  .indexWhere(
                                                    (e) => e['id'] == widget.ID,
                                                  )]["bio"] ==
                                              ""
                                          ? SizedBox.shrink()
                                          : Padding(
                                              padding: const EdgeInsets.all(
                                                4.0,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  color: kPrimaryVariant,
                                                ),
                                                width: 300,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "  Bio :",
                                                      style: TextStyle(
                                                        fontFamily: "cursive",
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 6,
                                                            right: 6,
                                                            bottom: 4,
                                                          ),
                                                      child: Text(
                                                        contacts["contacts"][contacts["contacts"]
                                                            .indexWhere(
                                                              (e) =>
                                                                  e['id'] ==
                                                                  widget.ID,
                                                            )]["bio"],
                                                        style: TextStyle(
                                                          fontFamily:
                                                              "times new roman",
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                      SizedBox(height: 7),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Hero(
                            tag:
                                contacts["contacts"][contacts["contacts"]
                                    .indexWhere(
                                      (e) => e['id'] == widget.ID,
                                    )]["chat_id"],
                            child: Container(
                              height: 40,
                              width: 40,
                              child: ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(10),
                                child: RepaintBoundary(
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        contacts["contacts"][contacts["contacts"]
                                            .indexWhere(
                                              (e) => e['id'] == widget.ID,
                                            )]["profile_pic"],
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
                                    memCacheWidth: 400,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                  ),
                                ),
                                // child: Image.network(contacts["contacts"][num]["profile_pic"]),
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
                                      ? const Color.fromARGB(177, 255, 255, 255)
                                      : Colors.black,
                                ),
                                contacts["contacts"][contacts["contacts"]
                                    .indexWhere(
                                      (e) => e['id'] == widget.ID,
                                    )]["name"],
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
            clipBehavior: Clip.hardEdge,
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
                            ? (chat["messages"][realIndex]["msg"].contains(
                                    SECRET_MARKER,
                                  )
                                  ? (chat["messages"][realIndex]["type"] ==
                                            "reply")
                                        ? receivedreply(realIndex)
                                        : received_image_base(realIndex)
                                  : (chat["messages"][realIndex]["type"] ==
                                        "message")
                                  ? recieved_msg(realIndex)
                                  : receivedreply(realIndex))
                            : (chat["messages"][realIndex]["msg"].contains(
                                    SECRET_MARKER,
                                  )
                                  ? (chat["messages"][realIndex]["type"] ==
                                            "reply")
                                        ? sendedreply(realIndex)
                                        : sent_image_base(realIndex)
                                  : (chat["messages"][realIndex]["type"] ==
                                        "message")
                                  ? sended_msg(realIndex)
                                  : sendedreply(realIndex));
                      },
                    ),
                  ),
                  typing_indi(),
                  SizedBox(height: 65),
                ],
              ),
              if (selectedImage != null)
                Positioned(
                  bottom: 55,
                  left: 10,
                  child: Align(
                    alignment: AlignmentGeometry.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12, right: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Isdark ? kTextPrimary : Colors.black,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(10),
                                child: Image.file(selectedImage!, height: 70),
                              ),
                              Positioned(
                                right: -17,
                                bottom: 40,
                                child: IconButton(
                                  icon: Icon(Icons.close),
                                  color: Colors.white,
                                  onPressed: () {
                                    setState(() => selectedImage = null);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (isreplying && replyid != -1)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  // height: 50,
                  child: replyingwid(),
                ),
              (!msg_sent && !isreplying)
                  ? (temp_msg != ""
                        ? Positioned(
                            bottom: 60,
                            left: 0,
                            right: 0,
                            child: temp_sended_msg(),
                          )
                        : SizedBox.shrink())
                  : SizedBox.shrink(),

              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13.0,
                    vertical: 1,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            width: 300,
                            height: 50,
                            child: TextField(
                              onChanged: (value) {
                                onTyping(widget.ID);
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

                                if (msg.contains("@Aurex")) {
                                    if(isreplying && replyid!=-1){
                                      gemini("{ ${chat["messages"][replyid]["msg"].toString().split("rpy").last} } in the curly bracket all text is from another person and i was replying it so based on that text answer me following question dont give other information"+msg);
                                    }else{gemini(msg);}
                                  }

                                if (isreplying) {
                                  if (replyid != -1)
                                    await send_message(
                                      "${chat["messages"][replyid]["sender_name"]} rpy ${chat["messages"][replyid]["msg"].toString().split("rpy").last} rpy ${msg}",
                                      "reply",
                                    );
                                  isreplying = false;
                                } else {
                                  await send_message(msg, "message");
                                }
                                temp_msg = "";
                              },
                              style: GoogleFonts.josefinSans(
                                color: Colors.black,
                              ),
                              controller: type_msg,
                              cursorColor: Colors.teal,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.alternate_email_rounded),
                                  color: Colors.black,
                                  iconSize: 23,
                                  onPressed: () {
                                    type_msg.text = "@Aurex ";
                                  },
                                ),
                                prefixIcon: IconButton(
                                  icon: Icon(Icons.wallpaper_rounded),
                                  color: Colors.black,
                                  iconSize: 23,
                                  onPressed: () async {
                                    HapticFeedback.selectionClick();
                                    final File? image =
                                        await pickImageFromGallery();
                                    if (image != null) {
                                      setState(() {
                                        selectedImage = image;
                                      });
                                    }
                                  },
                                ),
                                hint: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 7,
                                  ),
                                  child: Text(
                                    "Send across galaxy . . .",
                                    style: GoogleFonts.josefinSans(
                                      letterSpacing: 1.5,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                filled: true,
                                isDense: true,
                                fillColor: const Color.fromARGB(
                                  189,
                                  143,
                                  167,
                                  200,
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  // borderSide: BorderSide(
                                  //   color: (Isdark
                                  //       ? const Color.fromARGB(255, 255, 255, 255)
                                  //       : Colors.black),
                                  // ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  // borderSide: BorderSide(
                                  //   color: (Isdark ? Colors.white : Colors.black),
                                  // ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: const Color.fromARGB(
                                      0,
                                      255,
                                      255,
                                      255,
                                    ),
                                  ),
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
                              if (msg.contains("@Aurex")) {
                                    if(isreplying && replyid!=-1){
                                      gemini("{ ${chat["messages"][replyid]["msg"].toString().split("rpy").last} } in the curly bracket all text is from another person and i was replying it so based on that text answer me following question dont give other information"+msg);
                                    }else{gemini(msg);}
                                  }
                              if (msg != "") {
                                if (isreplying) {
                                  if (replyid != -1)
                                    await send_message(
                                      "${chat["messages"][replyid]["sender_name"]} rpy ${chat["messages"][replyid]["msg"].toString().split("rpy").last} rpy ${msg}",
                                      "reply",
                                    );
                                  isreplying = false;
                                  setState(() {});
                                  print("object 1");
                                } else if (selectedImage != null) {
                                  await uploadImageBase64(selectedImage!, msg);
                                } else {
                                  await send_message(msg, "message");
                                }
                              }

                              temp_msg = "";
                              selectedImage = null;
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.send_rounded,
                              size: 25,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //////  replying widget  //////
  Widget replyingwid() {
    return Align(
      alignment: AlignmentGeometry.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 10),
        child: Container(
          constraints: BoxConstraints(maxWidth: 270),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // color: Color(0xFF5BB9A8),
            color: const Color.fromARGB(255, 4, 195, 176),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: kDivider,
                      ),
                      constraints: BoxConstraints(maxHeight: 105),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                your_name == chat["messages"][replyid]["sender_name"].toString().trim()?"You":chat["messages"][replyid]["sender_name"],
                                // "Onkar",
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.exo2(
                                  // color: const Color.fromARGB(255, 2, 194, 174),
                                  color: kTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child:
                                  chat["messages"][replyid]["msg"]
                                      .toString()
                                      .split("rpy")
                                      .last
                                      .contains(SECRET_MARKER)
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadiusGeometry.circular(15),
                                      child: Image.network(
                                        fit: BoxFit.contain,
                                        chat["messages"][replyid]["msg"]
                                            .toString()
                                            .split(SECRET_MARKER)[1]
                                            .toString()
                                            .split("cpn")[0],
                                      ),
                                    )
                                  : Text(
                                      chat["messages"][replyid]["msg"]
                                          .toString()
                                          .split("rpy")
                                          .last,
                                      softWrap: true,
                                      style: GoogleFonts.josefinSans(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -10,
                      top: -10,
                      child: IconButton(
                        onPressed: () {
                          isreplying = false;
                          setState(() {});
                        },
                        icon: Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                // SizedBox(height: 5),
                Container(
                  // constraints: BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 150),
                        child: SingleChildScrollView(
                          child: Text(
                            temp_msg,
                            style: GoogleFonts.josefinSans(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //////  sended reply widget  //////

  Widget sendedreply(no) {
    final msg = chat["messages"][no]["msg"].toString().split("rpy");
    return Align(
      alignment: AlignmentGeometry.centerRight,
      child: GestureDetector(
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
                value: "reply",
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    SizedBox(width: 10),
                    Text("Reply"),
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
              Clipboard.setData(ClipboardData(text: msg.last));
            }
            if (value == "reply") {
              isreplying = true;
              replyid = no;
              setState(() {});
            }
            ;
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 10),
          child: Container(
            constraints: BoxConstraints(maxWidth: 270),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // color: Color(0xFF5BB9A8),
              color: Color.fromARGB(255, 130, 158, 190),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: kDivider,
                      ),
                      constraints: BoxConstraints(maxHeight: 105),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  your_name == msg[0].trim()?"You":msg[0],
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.exo2(
                                    // color: const Color.fromARGB(255, 2, 194, 174),
                                    color: kTextSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: msg[1].contains(SECRET_MARKER)
                                    ? GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return Dialog(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadiusGeometry.circular(
                                                        20,
                                                      ),
                                                  child: InteractiveViewer(
                                                    minScale: 1,
                                                    maxScale: 5,
                                                    child: Image.network(
                                                      filterQuality:
                                                          FilterQuality.high,
                                                      (msg[1]
                                                          .toString()
                                                          .split(
                                                            SECRET_MARKER,
                                                          )[1]
                                                          .trim()
                                                          .toString()
                                                          .split("cpn")[0]),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadiusGeometry.circular(10),
                                          child: Image.network(
                                            msg[1]
                                                .toString()
                                                .split(SECRET_MARKER)[1]
                                                .trim()
                                                .toString()
                                                .split("cpn")[0],
                                          ),
                                        ),
                                      )
                                    : Text(
                                        msg[1],
                                        softWrap: true,
                                        style: GoogleFonts.josefinSans(),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 150),
                            child: SingleChildScrollView(
                              child: Text(
                                msg[2],
                                style: GoogleFonts.josefinSans(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        "${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[0]}:${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[1]} ",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2), // X and Y position
                              blurRadius: 4, // Softness
                              color: Colors.black, // Shadow color
                            ),
                          ],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /////  received reply widget

  Widget receivedreply(no) {
    final msg = chat["messages"][no]["msg"].toString().split("rpy");
    return Align(
      alignment: AlignmentGeometry.centerLeft,
      child: GestureDetector(
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
                value: "reply",
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    SizedBox(width: 10),
                    Text("Reply"),
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
              Clipboard.setData(ClipboardData(text: msg[2]));
            }
            if (value == "reply") {
              isreplying = true;
              replyid = no;
              setState(() {});
            }
            ;
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 10),
          child: Container(
            constraints: BoxConstraints(maxWidth: 270),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // color: Color(0xFF5BB9A8),
              color: Color.fromARGB(255, 109, 168, 174),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: kDivider,
                      ),
                      constraints: BoxConstraints(maxHeight: 105),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  your_name == msg[0].trim()?"You":msg[0],
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.exo2(
                                    // color: const Color.fromARGB(255, 2, 194, 174),
                                    color: kTextSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: msg[1].contains(SECRET_MARKER)
                                    ? GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return Dialog(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadiusGeometry.circular(
                                                        20,
                                                      ),
                                                  child: InteractiveViewer(
                                                    minScale: 1,
                                                    maxScale: 5,
                                                    child: Image.network(
                                                      filterQuality:
                                                          FilterQuality.high,
                                                      (msg[1]
                                                          .toString()
                                                          .split(
                                                            SECRET_MARKER,
                                                          )[1]
                                                          .trim()
                                                          .toString()
                                                          .split("cpn")
                                                          .first),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadiusGeometry.circular(10),
                                          child: Image.network(
                                            msg[1]
                                                .toString()
                                                .split(SECRET_MARKER)[1]
                                                .trim()
                                                .toString()
                                                .split("cpn")[0],
                                          ),
                                        ),
                                      )
                                    : Text(
                                        msg[1],
                                        softWrap: true,
                                        style: GoogleFonts.josefinSans(),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(height: 5),
                    Container(
                      // constraints: BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 150),
                            child: SingleChildScrollView(
                              child: Text(
                                msg[2],
                                style: GoogleFonts.josefinSans(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        "${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[0]}:${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[1]} ",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2), // X and Y position
                              blurRadius: 4, // Softness
                              color: Colors.black, // Shadow color
                            ),
                          ],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget sent_image_base(int no) {
    bool imageloaded = false;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(20),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Image.network(
                    filterQuality: FilterQuality.high,
                    chat["messages"][no]["msg"].split(SECRET_MARKER)[1].toString()
                          .split("cpn")[0],
                  ),
                ),
              ),
            );
          },
        );
      },
      onLongPressStart: (details) {
        HapticFeedback.heavyImpact();
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
              value: "reply",
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Reply"),
                ],
              ),
            ),
            PopupMenuItem(
              value: "save_img",
              child: Row(
                children: [
                  Icon(Icons.save_alt_rounded, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Save Image"),
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
        ).then((value) async {
          if (value == "delete") {
            delete_msg(chat["messages"][no]["conversation_id"]);
            print("deleted");
          }
          if (value == "save_img") {
            await saveImageToGallery(
              chat["messages"][no]["msg"]
                  .split(SECRET_MARKER)[1]
                  .toString()
                  .split("cpn")[0],
            );
            print("img saved");
          }
          if (value == "reply") {
            isreplying = true;
            replyid = no;
            setState(() {});
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0, right: 12, left: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 130, 158, 190),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
              topLeft: Radius.circular(15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(12),
                  child: RepaintBoundary(
                    child: CachedNetworkImage(
                      filterQuality: FilterQuality.high,
                      imageUrl: chat["messages"][no]["msg"]
                          .split(SECRET_MARKER)[1]
                          .toString()
                          .split("cpn")[0],
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

                      memCacheWidth: 400,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                    ),
                  ),
                ),
              ),
              (chat["messages"][no]["msg"]
                              .split(SECRET_MARKER)[1]
                              .toString()
                              .split("cpn")
                              .last ==
                          null ||
                      chat["messages"][no]["msg"]
                          .split(SECRET_MARKER)[1]
                          .toString()
                          .split("cpn")
                          .last
                          .contains("https"))
                  ? SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(
                        left: 6.0,
                        top: 2,
                        right: 4,
                      ),
                      child: Text(
                        textAlign: TextAlign.start,
                        chat["messages"][no]["msg"]
                            .split(SECRET_MARKER)[1]
                            .toString()
                            .split("cpn")
                            .last,
                        style: GoogleFonts.josefinSans(color: Colors.black),
                      ),
                    ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 4),
                  child: Text(
                    textAlign: TextAlign.start,
                    "${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[0]}:${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[1]} ",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2), // X and Y position
                          blurRadius: 4, // Softness
                          color: Colors.black, // Shadow color
                        ),
                      ],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///// save img to gallery ////
  Future<void> saveImageToGallery(String imageUrl) async {
    try {
      final permission = await Permission.photos.request();
      if (!permission.isGranted) {
        print("❌ Permission denied");
        return;
      }
      final response = await http.get(Uri.parse(imageUrl));
      final Uint8List bytes = response.bodyBytes;
      final dir = Directory('/storage/emulated/0/Pictures/Galexi');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final filePath =
          '${dir.path}/galexi_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await MediaScanner.loadMedia(path: filePath);
      print("✅ Image saved & visible in Gallery");
    } catch (e) {
      print("❌ Save failed: $e");
    }
  }

  Widget received_image_base(int no) {
    bool imageloaded = false;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(20),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Image.network(
                    chat["messages"][no]["msg"]
                        .split(SECRET_MARKER)[1]
                        .toString()
                        .split("cpn")[0],
                  ),
                ),
              ),
            );
          },
        );
      },
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
              value: "reply",
              child: Row(
                children: [
                  Icon(
                    Icons.reply_rounded,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  SizedBox(width: 10),
                  Text("Reply"),
                ],
              ),
            ),
            PopupMenuItem(
              value: "save_img",
              child: Row(
                children: [
                  Icon(Icons.save_alt_rounded, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Save Image"),
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
        ).then((value) async {
          if (value == "delete") {
            delete_msg(chat["messages"][no]["conversation_id"]);
          }
          if (value == "save_img") {
            await saveImageToGallery(
              chat["messages"][no]["msg"]
                  .split(SECRET_MARKER)[1]
                  .toString()
                  .split("cpn")[0]
                  .trim()
                  .toString()
                  .split("cpn")[0],
            );
            print("saved");
          }
          if (value == "reply") {
            isreplying = true;
            replyid = no;
            setState(() {});
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0, left: 12, right: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 109, 168, 174),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(12),
                  child: RepaintBoundary(
                    child: CachedNetworkImage(
                      imageUrl: chat["messages"][no]["msg"]
                          .split(SECRET_MARKER)[1]
                          .toString()
                          .split("cpn")[0]
                          .trim(),
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
                      memCacheWidth: 400,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                    ),
                  ),
                ),
              ),

              (chat["messages"][no]["msg"]
                              .split(SECRET_MARKER)[1]
                              .toString()
                              .split("cpn")
                              .last ==
                          null ||
                      chat["messages"][no]["msg"]
                          .split(SECRET_MARKER)[1]
                          .toString()
                          .split("cpn")
                          .last
                          .contains("https"))
                  ? SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(
                        left: 6.0,
                        top: 2,
                        right: 4,
                      ),
                      child: Text(
                        textAlign: TextAlign.start,
                        chat["messages"][no]["msg"]
                            .split(SECRET_MARKER)[1]
                            .toString()
                            .split("cpn")
                            .last,
                        style: GoogleFonts.josefinSans(color: Colors.black),
                      ),
                    ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                  child: Text(
                    textAlign: TextAlign.start,
                    "${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[0]}:${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[1]} ",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2), // X and Y position
                          blurRadius: 4, // Softness
                          color: Colors.black, // Shadow color
                        ),
                      ],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///// image picker /////
  Future<File?> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      imageQuality: 20,
      source: ImageSource.gallery,
    );
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  //// upload image to database //////
  Future<void> uploadImageBase64(File imageFile, String msg) async {
    final bytes = await imageFile.readAsBytes();
    final url = await chatApi.uploadImageBase64(base64Encode(bytes));
    print("\n");
    print("🚀url 📷${url}");
    print("\n");
    await send_message("${SECRET_MARKER}${url}cpn${msg}", "image");
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
              value: "reply",
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  SizedBox(width: 10),
                  Text("Reply"),
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
          if (value == "reply") {
            isreplying = true;
            replyid = no;
            setState(() {});
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat["messages"][no]["msg"],
                    style: GoogleFonts.josefinSans(
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  Text(
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    "${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[0]}:${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[1]} ",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2), // X and Y position
                          blurRadius: 4, // Softness
                          color: Colors.black, // Shadow color
                        ),
                      ],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //////// sent message widget  ///////
  Widget sended_msg(int no) {
    return Transform.translate(
      offset: Offset(0, 0),
      child: GestureDetector(
        onPanUpdate: (details) {
          print("Swiped Left");
          setState(() {
            // details.delta.dx
            // left = left + 1;
            // // print(details.localPosition.dx);
            // print(left);
          });
          setState(() {});
        },
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
                value: "reply",
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    SizedBox(width: 10),
                    Text("Reply"),
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
              Clipboard.setData(
                ClipboardData(text: chat["messages"][no]["msg"]),
              );
            }
            if (value == "reply") {
              isreplying = true;
              replyid = no;
              setState(() {});
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
                border: Border.all(
                  color: const Color.fromARGB(0, 255, 255, 255),
                ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat["messages"][no]["msg"],
                      style: GoogleFonts.josefinSans(
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    Text(
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      "${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[0]}:${DateTime.parse(chat["messages"][no]["timestamp"]).toLocal().toString().split(" ")[1].split(".")[0].split(":")[1]} ",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2), // X and Y position
                            blurRadius: 4, // Softness
                            color: Colors.black, // Shadow color
                          ),
                        ],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
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
    if (temp_msg != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        child: Align(
          alignment: Alignment.topRight,
          child: Container(
            constraints: BoxConstraints(maxWidth: 270, maxHeight: 200),
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
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Text(
                  temp_msg,
                  style: GoogleFonts.josefinSans(color: Colors.black),
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

  /////  typing function ////
  Timer? _typingTimer;
  void onTyping(String receiverId) async {
    print("changed");
    final me = FirebaseAuth.instance.currentUser!.email!;
    final chatId = buildChatId(me, receiverId);
    print(1);
    await Supabase.instance.client.from('typing_status').upsert({
      'chat_id': chatId,
      'user_id': me,
      'is_typing': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    print(2);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 500), () async {
      await Supabase.instance.client
          .from('typing_status')
          .update({'is_typing': false})
          .eq('chat_id', chatId)
          .eq('user_id', me);
    });
    print(1);
  }

  ///// typing indicator  /////
  Widget typing_indi() {
    if (otherUserTyping) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            height: 30,
            width: 50,
            // constraints: BoxConstraints(maxWidth: 100, maxHeight: 60),
            decoration: BoxDecoration(
              color: kTextHint,
              // border: Border.all(color: const Color.fromARGB(237, 255, 255, 255)),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                topLeft: Radius.zero,
                bottomRight: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              // color:Color.fromARGB(50, 255, 255, 255),
            ),
            child: Lottie.asset("assets/lotties/Dots.json"),
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
    await chatApi.clearChat(chatId);
    user_contact();
    await all_chats_list();
    setState(() {});
    print("🚀🚀🚀 cleared chat line 1230 ");
  }

  ////// delete message  //////
  Future<void> delete_msg(int convo_id) async {
    final email = FirebaseAuth.instance.currentUser!.email!;
    await chatApi.deleteSingleMessage(chatId, convo_id);
    user_contact();
    await all_chats_list();
    HapticFeedback.heavyImpact();
    print("deleted ");
  }

  /////  refresh contacts   //////
  Future<void> user_contact() async {
    await appKey.currentState?.user_contacts();
  }

  ///////   chatbot   //////

  Future<void> gemini(String prompt) async {
    chatApi.fetch_api();
    print("asking 🚀🚀");
    String res = "Error";
    for (String apiKey in api_keys.value) {
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
      );

      try {
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
                        " imagine u as an ai build by astro and named Aurex of u and u are an commercial ai mode build for an app named aera, dont always mention all info about u just give answers which was asked and must have frendly tone dont give long info give just main info",
                  },
                ],
              },
            ],
          }),
        );

        print("Status: ${response.statusCode}");

        if (response.statusCode == 200) {
          res = jsonDecode(
            response.body,
          )["candidates"][0]["content"]["parts"][0]["text"];
          break;
        }
        if (response.statusCode == 429 ||
            response.statusCode == 401 ||
            response.statusCode == 403) {
          print("Key failed, trying next...");
          continue;
        } else {
          print("Other error: ${response.statusCode}");
          break;
        }
      } catch (e) {
        print("Exception: $e");
        continue;
      }
    }
    send_response(res);
    setState(() {});
  }

  Future<void> send_response(String msg) async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    await chatApi.addMessageFast(
      "Aurex AI",
      widget.ID,
      "Aurex AI\n\n" + msg,
      chatId,
      "message",
    );
    print("🚀🚀🚀🚀 response sent");
  }
}
