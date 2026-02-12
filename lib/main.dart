import 'dart:convert';
import 'package:Aera/chat_page.dart';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/essentials/functions.dart';
import 'package:Aera/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'home_page.dart';

final chatApi = SupabaseChatApi(
                notificationServerUrl: "https://us-central1-galexi-eebbe.cloudfunctions.net/sendFcmNotification",
              );

bool isdark = true;

final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


Future<void> setupNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for urgent notifications.',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'channelId',
    'channelName',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails notifDetails = NotificationDetails(
    android: androidDetails,
  );
  await fln.show(
    1,
    message.notification?.title,
    message.notification?.body,
    notifDetails,
  );
}


void handleNotificationNavigation(RemoteMessage message) async{
  // print("FCM DATA: ${message.data}");
  final type = message.data['type'];
  await appKey.currentState?.all_chats_list();
  if (type == 'chat') {
    // print("FCM DATA: ${message.data}");
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(ID:message.data["send_id"])
      ),
    );
  }
}


final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();


//////  MAIN  //////
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://qbppenfcbrszswmfmiop.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFicHBlbmZjYnJzenN3bWZtaW9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ1NjYzOTUsImV4cCI6MjA4MDE0MjM5NX0.8AAc948zNLMgESdauFKmLVJvBUHXwHntFRAYRfEdoWw",
  );
  await Hive.initFlutter();
  await Hive.openBox('cache');
  await Hive.openBox('isdark');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupNotificationChannel();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      handleNotificationNavigation(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    handleNotificationNavigation(message);
  });
  runApp(MyApp());
}

final GlobalKey<_MyAppState> appKey = GlobalKey<_MyAppState>();
class MyApp extends StatefulWidget {
  MyApp() : super(key: appKey);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void toggleTheme() {
    setState(() {
      isdark = !isdark;
      Hive.box('isdark').put("isDark", isdark);
    });
  }

  

  @override
  void initState() {
    super.initState();
    chatApi.setOnline();
    isdark = Hive.box("isdark").get("isDark") ?? true;
    retrive_data();
    update_last_seen();
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.getToken().then((token) {});
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      user_contacts();
      all_chats_list();
      print("🔔 Foreground message received");
    });
  }

  //////   message database initialize /////
  Future<void> all_chats_list() async {
    print("object");
    final email = FirebaseAuth.instance.currentUser?.email;
    all_msg_list.value = await chatApi.getAllChatsFormatted(email!);
    final box = Hive.box('cache');
    box.put('all_msg_list', all_msg_list.value);
    // print("🚀🚀🚀 : $all_msg_list.value");
    setState(() {});
  }

  ////// update user last seen /////
  Future<void> update_last_seen() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    await chatApi.updateLastSeen(email!);
    print("Last_seen_updated_successfully 📖");
    // print(jsonDecode(response.body));
    setState(() {});
  }

  Future<void> retrive_data() async {
    final box = Hive.box('cache');
    if (box.get('all_contacts') != null) {
      all_contacts.value = Map<String, dynamic>.from(box.get('all_contacts'));
    }
    if (box.get('all_msg_list') != null) {
      all_msg_list.value = Map<String, dynamic>.from(box.get('all_msg_list'));
    }
  }

  ////////  refresh contacts //////
  Future<void> user_contacts() async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    all_contacts.value = await chatApi.getUserContacts(email!);
    final box = Hive.box('cache');
    box.put('all_contacts', all_contacts.value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       navigatorKey: navigatorKey, 
      debugShowCheckedModeBanner: false,
      themeMode: isdark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      title: 'Aera',
      home: FirebaseAuth.instance.currentUser != null
          ? MyHomePage(toggleTheme: toggleTheme)
          : LoginPage(toggleTheme: toggleTheme),
    );
  }
}
