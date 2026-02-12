import 'dart:convert';

import 'package:Aera/chat_page.dart';
import 'package:Aera/essentials/colours.dart';
import 'package:Aera/main.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

TextEditingController textq = TextEditingController();
String res = "Onkar";
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            automaticallyImplyLeading: true,
            leading: IconButton(
              onPressed: () async {
                HapticFeedback.selectionClick();
                msg_sent = true;
                setState(() {});
                Navigator.pop(context);
                setState(() {});
              },
              icon: Icon(Icons.arrow_back_ios_new_rounded),
            ),
            leadingWidth: 30,
            title: SizedBox(
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
                                        tag:"chatBot",
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: RepaintBoundary(
                                            child:Image.asset("assets/images/dodge.jpg")
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text("ChatBot",
                                        style: TextStyle(
                                          fontFamily: "times new roman",
                                          fontSize: 10,
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
                            tag:"Chatbot",
                            child: Container(
                              height: 40,
                              width: 40,
                              child: ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(10),
                                child: RepaintBoundary(
                                  child: Image.asset("assets/images/dodge.jpg"),
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
                                  fontSize: 25,
                                  fontFamily: "cursive",
                                  color: Isdark ? Colors.white : Colors.black,
                                ),
                               "ChatBot",
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    // await clear_chat();
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
                  // Expanded(
                  //   child: ListView.builder(
                  //     reverse: true,
                  //     itemCount:
                  //         (chat["message_count"] == null ||
                  //             chat["message_count"] == 0)
                  //         ? 1
                  //         : chat["message_count"],
                  //     itemBuilder: (context, index) {
                  //       if (chat["message_count"] == null) {
                  //         return Center(child: SizedBox.shrink());
                  //       }
                  //       if (chat["message_count"] == 0) {
                  //         return SizedBox.shrink();
                  //       }
                  //       int realIndex = (chat["message_count"] - 1) - index;
                  //       if (chat["messages"][realIndex]["msg"] == "")
                  //         return SizedBox.shrink();
                  //       return chat["messages"][realIndex]["user_sent"] == "no"
                  //           ? (chat["messages"][realIndex]["msg"].contains(
                  //                   SECRET_MARKER,
                  //                 )
                  //                 ? received_image_base(realIndex)
                  //                 : recieved_msg(realIndex))
                  //           : (chat["messages"][realIndex]["msg"].contains(
                  //                   SECRET_MARKER,
                  //                 )
                  //                 ? sent_image_base(realIndex)
                  //                 : sended_msg(realIndex));
                  //     },
                  //   ),
                  // ),
                  // !msg_sent
                  //     ? (temp_msg != "" ? temp_sended_msg() : SizedBox.shrink())
                  //     : SizedBox.shrink(),

                  
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

                            // await send_message(msg);
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
                              // await send_message(msg);
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
        );
  }
  Future <void>gemini(String prompt)async{
    String apiKey = "AIzaSyCBT4vi-x_uTgZ7TiM3cQ-Xxmi-QcxGcos";
    final url = Uri.parse(
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
  );
  final response = await http.post(url,headers: {
    "Content-Type": "application/json",
  },
  body: jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    }),);
    print(response.body.toString());
    if(response.statusCode == 200){
      res = jsonDecode(response.body)["candidates"][0]["content"]["parts"][0]["text"];
    }
    setState(() {
      
    });
  }
}
