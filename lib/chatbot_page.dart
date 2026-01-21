import 'package:Aera/main.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

TextEditingController search = TextEditingController();

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Center(
        child: TextField(
          controller: search,
          onChanged: (value)async {
            final a = await chatApi.searchUsers(search.text);
            print(a);
            print("\n");
            print("\n");
          },
        ),
      )
    );
  }
}