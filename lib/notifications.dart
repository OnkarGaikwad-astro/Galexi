// import 'package:aurex_messenger/main.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';


// import 'dart:convert';
// import 'package:aurex_messenger/home_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:http/http.dart' as http;

// bool isdark = true;

// List<dynamic>? data;
// int? no_of_msg;
// String url = "https://vercel-server-ivory-six.vercel.app/";

// final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

// void main() async {

//   WidgetsFlutterBinding.ensureInitialized();
//   const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//   const InitializationSettings initSettings = InitializationSettings(android: androidInit);

//   await notificationsPlugin.initialize(initSettings);
//   await notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {

//   void toggleTheme() {
//     setState(() {
//       isdark = !isdark;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       themeMode: isdark ? ThemeMode.dark : ThemeMode.light,
//       theme: ThemeData.light(),
//       darkTheme: ThemeData.dark(),
//       title: 'Galexi',
//       home: MyHomePage(title: 'Galexi', toggleTheme: toggleTheme),
//     );
//   }
// }

// Future<void> showNotification() async {
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'channelId',
//     'channelName',
//     importance: Importance.max,
//     priority: Priority.high,
//   );
//   const NotificationDetails platformDetails = NotificationDetails(
//     android: androidDetails,
//   );
//   await notificationsPlugin.show(1, 'Hello!', 'Hello Onkar', platformDetails);
// }