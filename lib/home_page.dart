import 'dart:io';

import 'package:Aera/add_contact.dart';
import 'package:Aera/chat_page.dart';
import 'package:Aera/chatbot_page.dart';
import 'package:Aera/create_group.dart';
import 'package:Aera/essentials/colours.dart';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/essentials/functions.dart';
import 'package:Aera/group_chat.dart' hide SECRET_MARKER;
import 'package:Aera/login_page.dart';
import 'package:Aera/lotties_.dart';
import 'package:Aera/main.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:Aera/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Color chat_color = const Color.fromARGB(133, 16, 37, 79);
bool isdark = true;
late String your_name;
late RealtimeChannel presenceChannel;
late RealtimeChannel ContactChannel;
File? selectedImage;
Map<String, bool> onlineUsers = {};
late String name_change;
bool readonly = true;
String vector = "onkar";
bool img_uploaded = true;

class MyHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  MyHomePage({super.key, required this.toggleTheme});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isReady = false;
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
    // final a = await chatApi.markLastMsgSeen(email!, other_user);
    await user_contacts();
    setState(() {});
  }

  //////   chatlist widget  //////
  Widget chat_list(int num) {
    final user = FirebaseAuth.instance.currentUser!.email;
    bool msgSeen = true;
    final rawMsgSeen = all_msg_list
        .value["chats"][all_contacts
            .value["contacts"][num]["chat_id"]]["messages"]
        .last["msg_seen"];
    if (rawMsgSeen is Map<String, dynamic>) {
      msgSeen = rawMsgSeen[user];
    } else if (rawMsgSeen is String) {
      try {
        msgSeen = jsonDecode(rawMsgSeen)[user];
      } catch (e) {
        msgSeen = true;
      }
    }
    bool isOnline =
        onlineUsers[all_contacts.value["contacts"][num]["id"]] ?? false;
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

                    if (contacts["contacts"][num]["group"]) {
                      await chatApi.remove_member_from_group(
                        email!,
                        contacts["contacts"][num]["chat_id"],
                      );
                    } else {
                      await chatApi.removeContactAndClearChat(
                        email!,
                        contacts["contacts"][num]["id"],
                      );
                    }
                    await user_contacts();
                    print("removed");
                    setState(() {});
                  }
                });
              },

              onTap: () async {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => contacts["contacts"][num]["group"]
                        ? GroupChat(ID: contacts["contacts"][num]["chat_id"])
                        : ChatPage(ID: contacts["contacts"][num]["id"]),
                  ),
                );
              },
              child: Stack(
                children: [
                  Container(
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
                                                      BorderRadius.circular(25),
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
                                                          (imageSize * dpr)
                                                              .round(),
                                                      memCacheHeight:
                                                          (imageSize * dpr)
                                                              .round(),
                                                      fadeInDuration:
                                                          Duration.zero,
                                                      fadeOutDuration:
                                                          Duration.zero,
                                                      placeholder:
                                                          (
                                                            context,
                                                            url,
                                                          ) => const SizedBox(
                                                            height: 300,
                                                            child: Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            ),
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => const Icon(
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
                                                style: GoogleFonts.josefinSans(
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
                              tag: contacts["contacts"][num]["chat_id"],
                              child: Stack(
                                children: [
                                  Container(
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

                                        placeholder: (context, url) =>
                                            const Center(
                                              child: SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ],
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
                                          style: GoogleFonts.josefinSans(
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
                                      maxLines: 1,
                                      all_msg_list.value["chats"][all_contacts
                                                  .value["contacts"][num]["chat_id"]] !=
                                              null
                                          ? (all_msg_list
                                                    .value["chats"][all_contacts
                                                        .value["contacts"][num]["chat_id"]]["messages"]
                                                    .last["msg"]
                                                    .contains(SECRET_MARKER)
                                                ? " ◯ Image"
                                                : all_msg_list
                                                      .value["chats"][all_contacts
                                                          .value["contacts"][num]["chat_id"]]["messages"]
                                                      .last["msg"]
                                                      .toString()
                                                      .split("rpy")
                                                      .last)
                                          : "",
                                      style: GoogleFonts.exo2(
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
                        // Text(
                        //   "${DateTime.parse(all_contacts.value["contacts"][num]["last_message_time"]).toLocal().toString().split(" ")[0]} \n ${DateTime.parse(all_contacts.value["contacts"][num]["last_message_time"]).toLocal().toString().split(" ")[1].split(".")[0]} ",
                        //   style: TextStyle(
                        //     fontSize: 8,
                        //     fontFamily: "times new roman",
                        //     color: isdark
                        //         ? Colors.grey
                        //         : const Color.fromARGB(255, 72, 71, 71),
                        //   ),
                        // ),
                        SizedBox(width: 10),

                        SizedBox(width: 25),
                        (!msgSeen
                            ? Text("🚀", style: TextStyle(fontSize: 15))
                            : SizedBox.shrink()),
                      ],
                    ),
                  ),
                  isOnline && all_contacts.value["contacts"][num]["id"] != user
                      ? Positioned(
                          left: 0,
                          top: 0,
                          child: Icon(
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.teal),
                            ],
                            size: 20,
                            Icons.circle_sharp,
                            color: const Color.fromARGB(255, 0, 255, 106),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : SizedBox.shrink(),
                ],
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

  Future<void> userpres() async {
    await user_contacts();
    final contacts = all_contacts.value["contacts"] as List ?? [];
    final ids = contacts
        .map((c) => c["id"])
        .where((id) => id != null && id.toString().isNotEmpty)
        .toList();

    presenceChannel = Supabase.instance.client
        .channel('presence_subset')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_presence',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.inFilter,
            column: 'user_id',
            value: ids,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data == null) return;

            final userId = data['user_id'];

            setState(() {
              onlineUsers[userId] = data['is_online'] == true;
            });
          },
        )
        .subscribe();

    final chatids = contacts
        .map((c) => c["chat_id"])
        .where((id) => id != null && id.toString().isNotEmpty)
        .toList();

    ContactChannel = Supabase.instance.client
        .channel('last_message')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_contacts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.inFilter,
            column: 'chat_id',
            value: chatids,
          ),
          callback: (payload) async {
            print("🚀🚀🚀🚀🚀🚀🚀 ");
            final data = payload.newRecord;
            await user_contacts();
            all_chats_list();
            setState(() {});
          },
        )
        .subscribe();
  }

  Future<void> all_chats_list() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    all_msg_list.value = await chatApi.getAllChatsFormatted(email!);
    final box = Hive.box('messages');
    box.putAll(all_msg_list.value);
    setState(() {});
  }

  Future<void> fetch_on_contacts() async {
    final onn = await chatApi.on_contacts();
    onlineUsers = onn;
    print(onn);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    chatApi.fetch_api();
    fetch_on_contacts();
    all_chats_list();
    userpres();
    chatApi.savefcm();
    if (Hive.box("aurex_api").get("keys") != null) {
      api_keys.value = Hive.box("aurex_api").get("keys");
    }

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
  }

  @override
  void dispose() {
    presenceChannel.unsubscribe();
    chatApi.setOffline();
    super.dispose();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      chatApi.setOnline();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      chatApi.setOffline();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isdark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController namechange = TextEditingController();
    final TextEditingController vecontroller = TextEditingController();

    namechange.text = FirebaseAuth.instance.currentUser!.displayName ?? "Aera";
    return Scaffold(
      drawerEnableOpenDragGesture: false,
      drawerEdgeDragWidth: 200,

      drawer: SafeArea(
        child: Drawer(
          backgroundColor: kInputBorder,
          width: 300,
          child: Column(
            children: [
              SizedBox(height: 20),
              Container(
                height: 100,
                child: Stack(
                  children: [
                    Align(
                      alignment: AlignmentGeometry.center,
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(20),
                        child: CachedNetworkImage(
                          filterQuality: FilterQuality.high,
                          imageUrl:
                              FirebaseAuth.instance.currentUser!.photoURL!,
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
                      ),
                    ),
                    // !img_uploaded?Align(alignment: AlignmentGeometry.center,child: CircularProgressIndicator(color: Colors.black,)):SizedBox.shrink(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: AlignmentGeometry.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              throw Exception('User not logged in');
                            }
                            HapticFeedback.selectionClick();
                            final File? image = await pickImageFromGallery();
                            if (image != null) {
                              setState(() {
                                selectedImage = image;
                                img_uploaded = false;
                              });
                            }
                            final bytes = await selectedImage!.readAsBytes();
                            final url = await chatApi.uploadImageBase64(
                              base64Encode(bytes),
                            );

                            print(url);
                            await FirebaseAuth.instance.currentUser!
                                .updatePhotoURL(url);
                            img_uploaded = true;
                            setState(() {});
                            setState(() {});
                            await Supabase.instance.client
                                .from('users')
                                .update({
                                  'user_id': user.email,
                                  'profile_pic': url,
                                })
                                .eq('user_id', user.email!);
                          },
                          child: !img_uploaded
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 1,
                                  ),
                                )
                              : Icon(
                                  Icons.edit,
                                  size: 25,
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    255,
                                    255,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(15),
                            ),
                            backgroundColor: const Color.fromARGB(
                              255,
                              58,
                              83,
                              134,
                            ),
                            elevation: 7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      width: 210,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        color: const Color.fromARGB(118, 110, 156, 176),
                      ),
                      child: Center(
                        child: TextField(
                          // textAlign: TextAlign.center,
                          style: GoogleFonts.josefinSans(
                            color: const Color.fromARGB(255, 223, 255, 224),
                          ),
                          cursorColor: Colors.teal,
                          maxLines: 1,
                          enabled: true,
                          readOnly: readonly,
                          controller: namechange,
                          decoration: InputDecoration(
                            // filled: true,
                            isDense: true,
                            prefixIcon: IconButton(
                              onPressed: () {
                                readonly = !readonly;
                                print(readonly);
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.mode_edit_outline_outlined,
                                color: const Color.fromARGB(181, 120, 253, 239),
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(0, 255, 255, 255),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 7,
                        backgroundColor: const Color.fromARGB(255, 58, 83, 134),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          throw Exception('User not logged in');
                        }
                        readonly = true;
                        await FirebaseAuth.instance.currentUser!
                            .updateDisplayName(namechange.text);
                        setState(() {});
                        await Supabase.instance.client
                            .from('users')
                            .update({
                              'user_id': user.email,
                              'name': namechange.text,
                            })
                            .eq('user_id', user.email!);
                        print("Name changed");
                        print(FirebaseAuth.instance.currentUser!.displayName);
                      },
                      child: Icon(
                        Icons.task_alt,
                        color: const Color.fromARGB(255, 82, 255, 160),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  backgroundColor: const Color.fromARGB(148, 192, 228, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(15),
                  ),
                ),
                onPressed: () async {
                  chatApi.setOffline();
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
                child: Text(
                  "Logout !",
                  style: GoogleFonts.josefinSans(
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(215, 248, 3, 3),
                  ),
                ),
              ),
              // ElevatedButton(
              //   onPressed: () async {
              //     String query = "i am onkar";
              //     final queryEmbedding = await emb.generateEmbedding(query);
              //     final response = await Supabase.instance.client.rpc(
              //       'match_messages',
              //       params: {
              //         'query_embedding': queryEmbedding,
              //         'match_count': 5,
              //         "chat_id_filter":"groupchat"
              //       },
              //     );

              //     print(response);
              //   },
              //   child: Text("get"),
              // ),
              // ElevatedButton(
              //   onPressed: () async {
              //     final result = await Supabase.instance.client
              //         .from('messages')
              //         .select('msg')
              //         .filter('msg', 'ilike', '%name%')
              //         .limit(5);

              //     print(result.toString());
              //   },
              //   child: Text("Press me"),
              // ),
              // ElevatedButton(onPressed: () {
              //   final a = "@Aurex my name is onkar" ;
              //   print(a.split("@Aurex")[1]);
              // }, child: Text("data"))
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        elevation: 30,
        backgroundColor: kSentMessage,
        foregroundColor: const Color.fromARGB(255, 171, 195, 229),
        child: Icon(Icons.person_add_alt_1),
        onPressed: () {
          print("Onkar");
          HapticFeedback.heavyImpact();
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
          InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () async {
              HapticFeedback.heavyImpact();
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) {
              //       return ChatbotPage();
              //     },
              //   ),
              // );
              // final a = await chatApi.deleteMsgforuser("onkar.gaikwad@iitgn.ac.in__onkargaikwad3319@gmail.com", 1258);
              print(all_msg_list.value);
            },
            child: CircleAvatar(
              maxRadius: 15,
              backgroundColor: isdark ? kSentMessage : kTextHint,
              foregroundColor: Colors.white,
              // backgroundImage: AssetImage("assets/images/ai.png"),
              child: Image.asset(
                "assets/images/ai.png",
                color: isdark ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(width: 15),
          Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Scaffold.of(context).openDrawer();
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
              );
            },
          ),
        ],
        title: Text(
          "Aera",
          style: GoogleFonts.moiraiOne(
            letterSpacing: 17,
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
            child: contacts["contact_count"] == 0
                ? ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [Center(child: SizedBox.shrink())],
                  )
                : contacts["contact_count"] == null
                ? ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 300),
                      Center(
                        child: Lottie.asset(
                          "assets/lotties/Sandy_Loading.json",
                        ),
                      ),
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
}
