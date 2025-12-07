import 'dart:convert';

import 'package:Galexi/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';
import 'home_page.dart';


String master_url = "https://vercel-server-ivory-six.vercel.app/";

Map<String, dynamic> contacts = {};

bool isdark = true;
final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


Future<void> setupNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', 
    'High Importance Notifications',
    description: 'This channel is used for urgent notifications.',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
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



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupNotificationChannel();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}



class _MyAppState extends State<MyApp> {


  void toggleTheme() {
    setState(() {
      isdark = !isdark;
    });
  }



  @override
  
  void initState() {
    super.initState();
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.getToken().then((token) {});
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      user_contacts();
      print("🔔 Foreground message received");
    });
  }



////////  refresh contacts //////
  Future<void> user_contacts() async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    final response = await http.get(
      Uri.parse(master_url + "user_contacts/${email}"),
    );
    contacts = jsonDecode(response.body);
    print(contacts);
    setState(() {
      
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: isdark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      title: 'Galexi',
      home: FirebaseAuth.instance.currentUser!=null?MyHomePage(toggleTheme: toggleTheme,):LoginPage(toggleTheme: toggleTheme,),
    );
  }
}
