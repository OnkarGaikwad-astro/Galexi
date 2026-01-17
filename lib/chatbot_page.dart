import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late RtcEngine engine;
  bool joined = false;

  @override
  void initState() {
    super.initState();
    initCall();
  }

  Future<void> initCall() async {
    // Ask mic permission
    await Permission.microphone.request();

    engine = createAgoraRtcEngine();

    await engine.initialize(
      const RtcEngineContext(
        appId: "190106356",
      ),
    );

    await engine.enableAudio();

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => joined = true);
        },
        onUserJoined: (connection, uid, elapsed) {
          debugPrint("User joined: $uid");
        },
        onUserOffline: (connection, uid, reason) {
          debugPrint("User left: $uid");
        },
      ),
    );

    await engine.joinChannel(
      token: "", 
      channelId: "chat_123",
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    engine.leaveChannel();
    engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voice Call")),
      body: Center(
        child: Text(
          joined ? "Connected 🎧" : "Connecting...",
          style: const TextStyle(fontSize: 20),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.call_end),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}