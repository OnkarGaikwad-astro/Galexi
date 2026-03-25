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
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Color chat_color = const Color.fromARGB(133, 16, 37, 79);
bool isdark = true;
late String your_name;
late RealtimeChannel presenceChannel;
late RealtimeChannel ContactChannel;
Map<String, bool> onlineUsers = {};
late String name_change;
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
    // final a = await chatApi.markLastMsgSeen(email!, other_user);
    await user_contacts();
    setState(() {});
  }

  //////   chatlist widget  //////
  Widget chat_list(int num) {
    final user = FirebaseAuth.instance.currentUser!.email;
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
                                      all_contacts
                                              .value["contacts"][num]["last_msg"]
                                              .contains(SECRET_MARKER)
                                          ? " ◯ Image"
                                          : all_contacts
                                                .value["contacts"][num]["last_msg"],
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
                        SizedBox(width: 10,),
                     
                        // SizedBox(width: 25),
                        // !contacts["contacts"][num]["msg_seen"]
                        //     ? Text("🚀", style: TextStyle(fontSize: 15))
                        //     // ?Icon(Icons.mark_email_unread,color: Color.fromARGB(
                        //     //               255,
                        //     //               0,
                        //     //               255,
                        //     //               106,
                        //     //             ),)
                        //     : SizedBox.shrink(),
                      ],
                    ),
                  ),  isOnline && all_contacts.value["contacts"][num]["id"]!=user? Positioned(
                                left: 0,
                                top: 0,
                                child: Icon(
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.teal,
                                        ),
                                      ],
                                      size: 20,
                                      Icons.circle_sharp,
                                      color: const Color.fromARGB(
                                        255,
                                        0,
                                        255,
                                        106,
                                      ),
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



Future <void>userpres()async{
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
          callback: (payload) async{
            print("🚀🚀🚀🚀🚀🚀🚀 ");
            final data = payload.newRecord;
            await user_contacts();
            all_chats_list();
            setState(() {
            });
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

Future<void> fetch_on_contacts()async{
  final onn = await chatApi.on_contacts();
  onlineUsers = onn ;
  print(onn);
  setState(() {
  });
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
    bool editnamechange = false ;
    return Scaffold(
      drawerEnableOpenDragGesture: false,
      drawerEdgeDragWidth: 200,

      drawer: SafeArea(
        child: Drawer(
          backgroundColor:kInputBorder,
          width: 300,
          child: Column(
            children: [
              SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(20),
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
              ),
              // SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(width: 100,height: 35,decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),color: kTextHint),child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  // Text(FirebaseAuth.instance.currentUser!.displayName ?? "astro",style: GoogleFonts.josefinSans(color: const Color.fromARGB(255, 216, 240, 217)),),
                  child: TextField(enabled:editnamechange,controller: namechange,decoration: InputDecoration(
                    hint: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(FirebaseAuth.instance.currentUser!.displayName ?? "astro",style: GoogleFonts.josefinSans(color: const Color.fromARGB(255, 216, 240, 217)),),
                      ),
                    ),
                  ),),
                )),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.currentUser!.updateDisplayName(
                    "Onkar",
                  );
                  print("Name changed");
                  print(FirebaseAuth.instance.currentUser!.displayName);
                  setState(() {});
                },
                child: Text("Change name"),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Lottiepage();
                      },
                    ),
                  );
                },
                child: Text("lottie"),
              ),

              ElevatedButton(
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
                child: Text("Logout !"),
              ),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ChatbotPage();
                  },
                ),
              );
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
}
