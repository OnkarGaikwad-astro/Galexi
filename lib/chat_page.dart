import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:Aera/add_contact.dart';
import 'package:Aera/chatbot_page.dart';
import 'package:Aera/essentials/colours.dart';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

// String master_url = "https://messenger-api-86895289380.asia-south1.run.app/";
bool Isdark = true;
class ChatPage extends StatefulWidget {
  final dynamic ID;
  const ChatPage({super.key, required this.ID,});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

TextEditingController type_msg = TextEditingController();

String sender_last_seen = "";
String SECRET_MARKER = '\u{E000}';
bool msg_sent = true;
String temp_msg = "";

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  @override
  ///// fetch chat /////
  Map<String, dynamic> chat = <String, dynamic>{
    "message_count": 0,
    "messages": <dynamic>[],
  };

  File? selectedImage;

  Future<void> fetch_chat() async {
    print("🚀");
    final Map<String, dynamic> msg_list = Map<String, dynamic>.from(
      all_msg_list.value,
    );
    print("msg_list $msg_list");
    final Map<String, dynamic> contacts = Map<String, dynamic>.from(
      all_contacts.value,
    );
    print("contacts $contacts");
    final dynamic result = msg_list["chats"].firstWhere(
      (c) => c["contact_id"] == contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["id"],
      orElse: () => null,
    );
    if (result == null) {
      print("null");
      chat = {"message_count": 0, "messages": []};
    } else {
      print("hello");
      chat = Map<String, dynamic>.from(result);
      print("chat:${chat}");
    }
    print("chat:${chat}");
    print("result:${result}");
    print("all_msg_list.value:${all_msg_list.value}");
    setState(() {});
  }

  ///////   send message   ////
  Future<void> send_message(String msg) async {
    final contacts = all_contacts.value;
    final response = await http.post(
      Uri.parse(master_url + "add_message"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "sender_id": await FirebaseAuth.instance.currentUser?.email,
        "receiver_id": contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["id"],
        "msg": msg,
      }),
    );
    print("msg sent $response.body");
  }

  ///// sender_last_seen  /////

  Future<void> last_seen() async {
    final Map<String, dynamic> contacts = Map<String, dynamic>.from(
      all_contacts.value,
    );
    print("last_seen_fetch_start");
    final response = await http.get(
      Uri.parse(
        master_url + "last_seen/${contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["id"]}",
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
    all_msg_list.value = Map<String, dynamic>.from(jsonDecode(response.body));
    final box = Hive.box('cache');
    await box.put('all_msg_list', all_msg_list.value);
    print("😅 SAVEX");
    print(all_msg_list.value);
    print(all_msg_list.value);
    await fetch_chat();
    msg_sent = true;
    setState(() {});
  }

  ///
  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  // ///  refresh msgs when app resumes from home /////

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      all_chats_list(); // 🔑 refresh messages
    }
  }

  ///

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: true, // allow back navigation
        onPopInvoked: (didPop) {
          if (didPop) {
            print("🚀DEVICE BACK BUTTON PRESSED");
            hideSendingPopup();
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          // backgroundColor: Colors.black,
          appBar: AppBar(
            automaticallyImplyLeading: true,
            leading: IconButton(
              onPressed: () async {
                HapticFeedback.selectionClick();
                msg_sent = true;
                setState(() {});
                hideSendingPopup();
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
                                        tag: contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["name"],
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: RepaintBoundary(
                                            child: CachedNetworkImage(
                                              imageUrl: highQualityUrl(
                                                contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["profile_pic"],
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
                                      const SizedBox(height: 6),
                                      Text(
                                        contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["name"],
                                        style: TextStyle(
                                          fontFamily: "times new roman",
                                          fontSize: 10,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["bio"]==""?SizedBox.shrink():Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),color: kPrimaryVariant),width: 300,child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // SizedBox(height: 3,),
                                            Text("  Bio :",style: TextStyle(fontFamily: "cursive",fontWeight: FontWeight.w800),),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 6,right: 6,bottom: 4),
                                              child: Text(contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["bio"],style: TextStyle(fontFamily: "times new roman")),
                                            )
                                          ],
                                        ),),
                                      ),
                                      SizedBox(height: 7,)
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
                            tag:contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["name"],
                            child: Container(
                              height: 40,
                              width: 40,
                              child: ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(10),
                                child: RepaintBoundary(
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["profile_pic"],
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
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: "times new roman",
                                  color:  Isdark ? Colors.white:Colors.black
                                ),
                                contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["name"],
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                          : chat["message_count"] - 1,
                      itemBuilder: (context, index) {
                        if (chat["message_count"] == null){
                          return Center(
                            child: Lottie.asset(
                              "assets/lotties/paperplane.json",
                            ),
                          );
                        }if(chat["message_count"] == 0){
                          return SizedBox.shrink();
                        }
                        int realIndex = (chat["message_count"] - 1) - index;
                        if (realIndex == 0) return SizedBox.shrink();
                        return chat["messages"][realIndex]["user_sent"] == "no"
                            ? (chat["messages"][realIndex]["msg"].contains(
                                    SECRET_MARKER,
                                  )
                                  ? received_image_base(realIndex)
                                  : recieved_msg(realIndex))
                            : (chat["messages"][realIndex]["msg"].contains(
                                    SECRET_MARKER,
                                  )
                                  ? sent_image_base(realIndex)
                                  : sended_msg(realIndex));
                      },
                    ),
                  ),
                  !msg_sent
                      ? (temp_msg != "" ? temp_sended_msg() : SizedBox.shrink())
                      : SizedBox.shrink(),

                  if (selectedImage != null)
                    Align(
                      alignment: AlignmentGeometry.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12, right: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Isdark? kTextPrimary : Colors.black,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    10,
                                  ),
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
                  SizedBox(height: 65),
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
                          HapticFeedback.selectionClick();
                          msg_sent = false;
                          setState(() {});
                          showSendingPopup(context, "Sending....");
                          final msg = type_msg.text;
                          type_msg.text = "";
                          
                          await send_message(msg);
                          await all_chats_list();
                          temp_msg = "";
                          hideSendingPopup();
                        },
                        controller: type_msg,
                        cursorColor: Colors.teal,
                        decoration: InputDecoration(
                          prefixIcon: IconButton(
                            icon: Icon(Icons.photo_size_select_actual_rounded),
                            color: const Color.fromARGB(255, 150, 215, 245),
                            onPressed: () async {
                              HapticFeedback.selectionClick();
                              final File? image = await pickImageFromGallery();
                              if (image != null) {
                                setState(() {
                                  selectedImage = image;
                                });
                              }
                            },
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
                              color: (Isdark
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : Colors.black),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: (Isdark
                                  ? Colors.white
                                  : Colors.black),
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
                          showSendingPopup(context, "Sending....");
                          final msg = type_msg.text;
                          type_msg.text = "";
                          
                          if (msg != null) {
                            await send_message(msg);
                          }
                          if (selectedImage != null) {
                            await uploadImageBase64(selectedImage!);
                          }
                          await all_chats_list();
                          temp_msg="";
                          hideSendingPopup();
                          selectedImage = null;
                          setState(() {});
                        },
                        icon: Icon(Icons.send_rounded, size: 25),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    chat["messages"][no]["msg"].split(SECRET_MARKER)[1],
                  ),
                ),
              ),
            );
          },
        );
      },
      onLongPressStart: (details) {
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
              value: "save_img",
              child: Row(
                children: [
                  Icon(Icons.save_alt_rounded, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Save Image"),
                ],
              ),
            ),
          ],
        ).then((value) async {
          if (value == "delete") {
            showSendingPopup(context, "Deleting...");
            delete_msg(no);
          }
          if (value == "save_img") {
            showSendingPopup(context, "Saving...");
            await saveImageToGallery(
              chat["messages"][no]["msg"].split(SECRET_MARKER)[1],
            );
            print("sended");
            hideSendingPopup();
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
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(12),
              child: RepaintBoundary(
                child: CachedNetworkImage(
                  filterQuality: FilterQuality.high,
                  imageUrl: chat["messages"][no]["msg"].split(SECRET_MARKER)[1],
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
                    chat["messages"][no]["msg"].split(SECRET_MARKER)[1],
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
              value: "save_img",
              child: Row(
                children: [
                  Icon(Icons.save_alt_rounded, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Save Image"),
                ],
              ),
            ),
          ],
        ).then((value) async {
          if (value == "delete") {
            showSendingPopup(context, "Deleting...");
            delete_msg(no);
          }
          if (value == "save_img") {
            showSendingPopup(context, "Saving...");
            await saveImageToGallery(
              chat["messages"][no]["msg"].split(SECRET_MARKER)[1],
            );
            print("saved");
            hideSendingPopup();
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
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(12),
              child: RepaintBoundary(
                child: CachedNetworkImage(
                  imageUrl: chat["messages"][no]["msg"].split(SECRET_MARKER)[1],
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
  Future<void> uploadImageBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final response = await http.post(
      Uri.parse("${master_url}upload_image"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"file": base64Encode(bytes)}),
    );
    print("🚀${jsonDecode(response.body)["url"]}");
    await send_message("${SECRET_MARKER}${jsonDecode(response.body)["url"]}");
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
          ],
        ).then((value) {
          if (value == "delete") {
            showSendingPopup(context, "Deleting...");
            delete_msg(no);
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

  ///////  sending popup /////
  OverlayEntry? sendingPopup;
  void showSendingPopup(BuildContext context, String text) {
    if (sendingPopup != null) return;
    sendingPopup = OverlayEntry(
      builder: (context) {
        double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        return Positioned(
          bottom: keyboardHeight + 80,
          left: 130,
          right: 130,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 34, 54, 96),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: "cursive",
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(sendingPopup!);
  }

  void hideSendingPopup() {
    sendingPopup?.remove();
    sendingPopup = null;
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
          ],
        ).then((value) {
          if (value == "delete") {
            showSendingPopup(context, "Deleting...");
            delete_msg(no);
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
    showSendingPopup(context, "Clearing ...");
    final email = FirebaseAuth.instance.currentUser?.email;
    final response = await http.delete(
      Uri.parse(
        master_url +
            "clear_chat/${email}/${contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["id"]}",
      ),
      headers: {"Content-Type": "application/json"},
    );
    await all_chats_list();
    await fetch_chat();
    user_contact();
    setState(() {});
    print(response.body);
    hideSendingPopup();
  }

  ////// delete message  //////
  Future<void> delete_msg(int convo_id) async {
    final contacts = all_contacts.value;
    final email = FirebaseAuth.instance.currentUser?.email;
    final response = await http.delete(
      Uri.parse(
        master_url +
            "delete_message/${email}/${contacts["contacts"][contacts["contacts"].indexWhere((e) => e['id'] == widget.ID)]["id"]}/${convo_id}",
      ),
      headers: {"Content-Type": "application/json"},
    );
    await all_chats_list();
    await fetch_chat();
    hideSendingPopup();
    user_contact();
    setState(() {});
    print(response.body);
  }

  /////  refresh contacts   //////
  Future<void> user_contact() async {
    await appKey.currentState?.user_contacts();
  }
}
