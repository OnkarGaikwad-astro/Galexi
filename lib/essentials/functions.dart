import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseChatApi {
  final SupabaseClient _db = Supabase.instance.client;
  final String notificationServerUrl;
  SupabaseChatApi({required this.notificationServerUrl});
  String _istNow() =>
      DateFormat('yyyy-MM-dd \n HH:mm:ss').format(DateTime.now());

  ////   fetch aurex api key   /////
  Future<void> fetch_api() async {
    final response = await _db.from("aurex_api").select("keys");
    api_keys.value = List<String>.from(response.first["keys"]);
    Hive.box(
      "aurex_api",
    ).put("keys", List<String>.from(response.first["keys"]));
  }

  ////  save user  ////

  Future<void> saveUser(String bio) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final data = {
      'user_id': user.email,
      'name': user.displayName,
      'fcm_token': fcmToken,
      'bio': bio,
      'profile_pic': user.photoURL,
      'phone_no': user.phoneNumber,
      'last_seen': _istNow(),
    };
    final existing = await _db
        .from('users')
        .select('user_id')
        .eq('user_id', user.email!)
        .maybeSingle();
    if (existing != null) {
      await _db.from('users').update(data).eq('user_id', user.email!);
    } else {
      await _db.from('users').insert(data);
    }
  }

  /////  save fcm token  //////

  Future<void> savefcm() async {
    print("saving fcm");
    final user = await FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final fcm = await FirebaseMessaging.instance.getToken();
    final existing = await _db
        .from('users')
        .select('user_id')
        .eq('user_id', user.email!)
        .maybeSingle();
    if (existing != null) {
      await _db
          .from('users')
          .update({"fcm_token": fcm})
          .eq('user_id', user.email!);
    }
    print("saved");
  }

  ////  get user info  ////
  Future<Map<String, dynamic>?> getUser(String userId) async {
    return await _db.from('users').select().eq('user_id', userId).maybeSingle();
  }

  //// list of all users  /////

  Future<Map<String, dynamic>> getAllUsers() async {
    final rows = await _db
        .from('users')
        .select(
          'id,user_id,name,bio,fcm_token,phone_no,profile_pic,last_seen,updated_at',
        );
    return {'count': rows.length, 'users': rows};
  }


Future<Map<String, dynamic>> getUsers({int page = 0, int limit = 20}) async {
  final from = page * limit;
  final to = from + limit - 1;

  final rows = await _db
      .from('users')
      .select(
        'id,user_id,name,bio,fcm_token,phone_no,profile_pic,last_seen,updated_at',
      )
      .range(from, to); 
  return {
    'count': rows.length,
    'users': rows,
  };
}
  ////  all users info  ////

  Future<List> allUsersInfo() async {
    return await _db.from('users').select();
  }

  ////  update last seen  ////

  Future<void> updateLastSeen(String userId) async {
    await _db
        .from('users')
        .update({'last_seen': _istNow()})
        .eq('user_id', userId);
  }

  /////  update last message  ////
  Future<void> updatelastmsg(String chatid, String msg) async {
    await _db
        .from('user_contacts')
        .update({
          'last_msg': msg,
          "last_msg_time": DateTime.now().toUtc().toIso8601String(),
        })
        .eq('chat_id', chatid);
  }

  /////  get last seen  /////

  Future<String?> getLastSeen(String userId) async {
    final r = await _db
        .from('users')
        .select('last_seen')
        .eq('user_id', userId)
        .maybeSingle();
    return r?['last_seen'];
  }

  Future<void> touchLastSeen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db
        .from('users')
        .update({'last_seen': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', user.email!);
  }

  /////  mark msg seen  ////

  Future<void> markLastMsgSeen(String chatId,int no) async {
    print("🚀🚀🚀 start");
    print(chatId);
    final user = await FirebaseAuth.instance.currentUser!.email!;
    final data = await _db
        .from('user_contacts')
        .select('msg_seen')
        .eq('chat_id', chatId)
        .maybeSingle();

    final raw = data!['msg_seen'];

    Map<String, dynamic> members;

    if (raw is String) {
      members = jsonDecode(raw);
    } else {
      members = Map<String, dynamic>.from(raw);
    }
    if(members[user] == false){
    members[user] = true;
    await Supabase.instance.client
        .from('user_contacts')
        .update({"msg_seen": jsonEncode(members)})
        .eq("chat_id", chatId);

    await Supabase.instance.client
        .from('messages')
        .update({"msg_seen": jsonEncode(members)})
        .eq("chat_id", chatId);
    }

    print("end");
  }

  Future<void> markMsgSeen(String chatId,int convo_id,final raw) async {
    print("🚀🚀🚀 start");
    print(chatId);
    final user = await FirebaseAuth.instance.currentUser!.email!;
    Map<String, dynamic> members;

    if (raw is String) {
      members = jsonDecode(raw);
    } else {
      members = Map<String, dynamic>.from(raw);
    }
    if(members[user] == false){
      print(members);
    members[user] = true;
    await Supabase.instance.client
        .from('messages')
        .update({"msg_seen": jsonEncode(members)})
        .or(
          'and(chat_id.eq.$chatId,conversation_id.eq.$convo_id)',
        );
    }
    print("end");
  }

  /////  user status /////

  Future <Map<String, bool>> on_contacts()async{
    final contacts = all_contacts.value["contacts"] as List ?? [];
    Map<String, bool> on_users = {};
    final ids = contacts
        .map((c) => c["id"])
        .where((id) => id != null && id.toString().isNotEmpty)
        .toList();
    final users = await _db.from("user_presence").select("user_id,is_online").inFilter("user_id", ids);

    for(final i in users){
      on_users[i["user_id"]] = i["is_online"];
    }
    return on_users;
  }

  Future<void> setOnline() async {
    final user = await FirebaseAuth.instance.currentUser!.email!;
    await Supabase.instance.client.from('user_presence').upsert({
      'user_id': user,
      'is_online': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<bool> getuserpresence(String id) async {
    final status = await Supabase.instance.client
        .from('user_presence')
        .select('is_online')
        .eq("user_id", id)
        .maybeSingle();
    return status?["is_online"] ?? false;
  }

  Future<void> setOffline() async {
    final user = await FirebaseAuth.instance.currentUser!.email!;
    await Supabase.instance.client
        .from('user_presence')
        .update({
          'is_online': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', user);
  }

  // /////  add contact /////
  // Future<Map<String, dynamic>> addContact(
  //   String userId,
  //   String contactId,
  // ) async {
  //   final existing = await _db
  //       .from('user_contacts')
  //       .select('id')
  //       .eq('user_id', userId)
  //       .eq('contact_id', contactId)
  //       .maybeSingle();
  //   if (existing != null) {
  //     return {'status': 'already_exists'};
  //   }
  //   await _db.from('user_contacts').insert({
  //     'user_id': userId,

  //     'contact_id': contactId,
  //   });
  //   addMessageFast(userId, contactId, "");
  //   return {'status': 'contact_added'};
  // }

  Future<Map<String, dynamic>> addContact(
    String userId,
    String contactId,
  ) async {
    final chatid = buildChatId(userId, contactId);
    final existing = await _db
        .from('user_contacts')
        .select('chat_id, members')
        .or(
          'and(user_1_id.eq.$userId,user_2_id.eq.$contactId),'
          'and(user_1_id.eq.$contactId,user_2_id.eq.$userId)',
        )
        .maybeSingle();
    List members = existing?['members'] ?? [];

    if (existing != null) {
      return {'status': 'already_exists'};
    }
    members.add(contactId);
    members.add(userId);
    await _db.from('user_contacts').insert({
      'user_1_id': userId,
      "user_2_id": contactId,
      "members": members,
      "chat_id": chatid,
    });

    //   // addMessageFast(userId, contactId, "");
    return {'status': 'contact_added'};
  }

  ////  get user contacts list  /////

  // Future<Map<String, dynamic>> getUserContacts(String userId) async {
  //   final manualRows = await _db
  //       .from('user_contacts')
  //       .select('contact_id')
  //       .eq('user_id', userId);
  //   final manualSet = <String>{
  //     for (final r in manualRows) r['contact_id'] as String,
  //   };
  //   final msgRows = await _db
  //       .from('messages')
  //       .select('sender_id,receiver_id,msg,msg_seen,timestamp')
  //       .or('sender_id.eq.$userId,receiver_id.eq.$userId')
  //       .order('timestamp', ascending: false);
  //   final Map<String, Map<String, dynamic>> contactMap = {};
  //   for (final msg in msgRows) {
  //     final sender = msg['sender_id'] as String;
  //     final receiver = msg['receiver_id'] as String;
  //     final other = sender == userId ? receiver : sender;
  //     if (!contactMap.containsKey(other)) {
  //       contactMap[other] = {
  //         'id': other,
  //         'last_message': msg['msg'],
  //         'last_message_time': msg['timestamp'],
  //         'last_message_sender_id': sender,
  //         'msg_seen': sender == userId ? 'seen' : (msg['msg_seen'] ?? ''),
  //       };
  //     }
  //   }
  //   for (final id in manualSet) {
  //     contactMap.putIfAbsent(
  //       id,
  //       () => {
  //         'id': id,
  //         'last_message': '',
  //         'last_message_time': '',
  //         'last_message_sender_id': '',
  //         'msg_seen': '',
  //       },
  //     );
  //   }
  //   if (contactMap.isEmpty) {
  //     return {'contact_count': 0, 'contacts': []};
  //   }
  //   final ids = contactMap.keys.join(',');
  //   final userRows = await _db
  //       .from('users')
  //       .select('user_id,name,profile_pic,bio,fcm_token')
  //       .inFilter('user_id', contactMap.keys.toList());
  //   final List<Map<String, dynamic>> contacts = [];
  //   for (final u in userRows) {
  //     final uid = u['user_id'];
  //     final info = contactMap[uid]!;
  //     contacts.add({
  //       'id': uid,
  //       'name': u['name'] ?? '',
  //       'profile_pic': u['profile_pic'] ?? '',
  //       'bio': u['bio'] ?? '',
  //       'fcm_token': u['fcm_token'],
  //       'last_message': info['last_message'],
  //       'last_message_time': info['last_message_time'],
  //       'last_message_sender_id': info['last_message_sender_id'],
  //       'msg_seen': info['msg_seen'],
  //     });
  //   }
  //   return {'contact_count': contacts.length, 'contacts': contacts};
  // }

  Future<Map<String, dynamic>> getUserContacts(String userId) async {
    final manualRows = await _db
        .from('user_contacts')
        .select(
          'user_1_id,user_2_id,chat_id,name,members,profile_pic,last_msg,group,last_msg_time,msg_seen',
        )
        .or("user_1_id.eq.$userId,user_2_id.eq.$userId,members.cs.{${userId}}")
        .order("last_msg_time", ascending: false);

    final contactlst = manualRows.map<Map<String, dynamic>>((row) {
      Map<String, dynamic> seenMap = {};
      final rawSeen = row["msg_seen"];
      if (rawSeen is Map) {
        seenMap = Map<String, dynamic>.from(rawSeen);
      } else if (rawSeen is String && rawSeen.isNotEmpty) {
        seenMap = Map<String, dynamic>.from(jsonDecode(rawSeen));
      }

      final bool seen = seenMap[userId] ?? false;

      final otherUserId = row['user_1_id'] == userId
          ? row['user_2_id']
          : row['user_1_id'];
      return {
        "id": otherUserId,
        "chat_id": row['chat_id'],
        "name": row["name"],
        "members": row["members"],
        "profile_pic": row["profile_pic"],
        "last_msg": row["last_msg"],
        "group": row["group"],
        "last_msg_time": row["last_msg_time"],
        "msg_seen": seen,
      };
    }).toList();

    final Map<String, Map<String, dynamic>> contactMap = {};

    for (final id in contactlst) {
      contactMap.putIfAbsent(
        id["id"],
        () => {
          'id': id["id"],
          'msg_seen': false,
          "name": id["name"],
          "chat_id": id["chat_id"],
          "members": id["members"],
          "profile_pic": id["profile_pic"],
          "last_msg": id["last_msg"],
          "last_msg_time": id["last_msg_time"],
          "group": id["group"],
        },
      );
    }

    if (contactMap.isEmpty) {
      return {'contact_count': 0, 'contacts': []};
    }

    final userRows = await _db
        .from('users')
        .select('user_id,name,profile_pic,bio,fcm_token')
        .inFilter('user_id', contactMap.keys.toList());

    final userMap = {for (final user in userRows) user['user_id']: user};

    final List<Map<String, dynamic>> contacts = [];
    for (final u in contactlst) {
      final uid = u['id'];
      final userData = userMap[uid];

      contacts.add({
        'id': uid,
        'name': u["group"] ? (u['name'] ?? '') : (userData?['name'] ?? ''),
        'profile_pic': u["group"]
            ? (u['profile_pic'] ?? '')
            : (userData?["profile_pic"] ?? ''),
        'bio': u["group"] ? (u['bio'] ?? '') : (userData?['bio'] ?? ''),
        'fcm_token': u["group"] ? null : userData?['fcm_token'],
        "chat_id": u["chat_id"],
        'msg_seen': u["msg_seen"],
        "members": u["members"],
        "group": u["group"],
        "last_msg": u["last_msg"] ?? "",
        "last_msg_time": u["last_msg_time"] ?? "",
      });
    }
    contacts.sort((a, b) {
      final t1 = DateTime.tryParse(a['last_msg_time'] ?? '') ?? DateTime(1970);
      final t2 = DateTime.tryParse(b['last_msg_time'] ?? '') ?? DateTime(1970);
      return t2.compareTo(t1); // newest first
    });
    return {'contact_count': contacts.length, 'contacts': contacts};
  }

  ////  remove user contact and clear chat  ////

  Future<void> removeContactAndClearChat(String u1, String u2) async {
    await _db
        .from('messages')
        .delete()
        .or(
          'and(sender_id.eq.$u1,receiver_id.eq.$u2),and(sender_id.eq.$u2,receiver_id.eq.$u1)',
        );
    await _db
        .from('user_contacts')
        .delete()
        .or(
          'and(user_1_id.eq.$u1,user_2_id.eq.$u2),and(user_1_id.eq.$u2,user_2_id.eq.$u1)',
        );
  }

  Future<String?> _findChat(String a, String b) async {
    final r = await _db
        .from('messages')
        .select('chat_id')
        .or(
          'and(sender_id.eq.$a,receiver_id.eq.$b),and(sender_id.eq.$b,receiver_id.eq.$a)',
        )
        .limit(1);
    return r.isEmpty ? null : r.first['chat_id'];
  }

  /////  add message   /////
  String buildChatId(String a, String b) {
    final pair = [a, b]..sort();
    return pair.join("__");
  }

  Future<String?> getUsersTokenforgrp(String userId) async {
    final r = await _db
        .from('users')
        .select('fcm_token')
        .eq('user_id', userId)
        .maybeSingle();
    return r?['fcm_token'];
  }

  Future<void> addMessageFast(
    String sender,
    String receiver,
    String msg,
    String chatId,
    String type,
  ) async {
    // final chatId = buildChatId(sender, receiver);
    // updatelastmsg(chatId, msg);
    final embed = emb.generateEmbedding(msg);
    final members =
        all_contacts.value["contacts"][all_contacts.value["contacts"]
            .indexWhere((e) => e['chat_id'] == chatId)]["members"];
    Map<String, dynamic> seen_data = {};
    for (final i in members) {
      seen_data[i] = sender == i ? true : false;
    }
    final name = (sender != "Aurex AI")
        ? await FirebaseAuth.instance.currentUser!.displayName
        : "Aurex AI";
    await _db.from('messages').insert({
      'chat_id': chatId,
      'sender_id': sender,
      'receiver_id': receiver,
      "members": members,
      'msg': msg,
      "type": type,
      "msg_seen": jsonEncode(seen_data),
      "sender_name": name,
      "embedding":embed
    });

    await _db
        .from('user_contacts')
        .update({
          'last_msg': msg,
          "last_msg_time": DateTime.now().toUtc().toIso8601String(),
          "msg_seen": seen_data,
        })
        .eq('chat_id', chatId);

    print("fetching fcm 😋 ");
    final fcm = await getUserToken(receiver);
    print("😋😋😋 fcm token :${fcm}");
    if (fcm != null && fcm.isNotEmpty) {
      Future.microtask(() {
        http.post(
          Uri.parse(notificationServerUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'token': fcm,
            'title': sender == "Aurex AI"
                ? "Aurex AI"
                : FirebaseAuth.instance.currentUser?.displayName,
            'body': msg.contains('\uE000') ? '⦿ Image' : msg,
            'send_id': sender,
          }),
        );
      });
    }
  }

  Future<void> addMsgforchatbot(
    String sender,
    String receiver,
    String msg,
    String type,
    String sender_name,
  ) async {
    final embed = emb.generateEmbedding(msg);
    final user = FirebaseAuth.instance.currentUser!.email;
    final chatId = buildChatId(sender, receiver);
    updatelastmsg(chatId, msg);
    final members = ["chatbot", user];

    await _db.from('messages').insert({
      'chat_id': chatId,
      'sender_id': sender,
      'receiver_id': receiver,
      "members": members,
      "sender_name": sender_name,
      "type": type,
      'msg': msg,
      "embedding":embed
    });
  }

  Future<void> addMessagegrp(
    String sender,
    String chatId,
    String msg,
    String type,
    bool bot,
  ) async {
    final embed = emb.generateEmbedding(msg);
    // updatelastmsg(chatId, msg);
    final profpic = bot
        ? "https://qbppenfcbrszswmfmiop.supabase.co/storage/v1/object/public/images/uploads/ai.png"
        : FirebaseAuth.instance.currentUser!.photoURL;
    final name = bot
        ? "Aurex Ai"
        : await FirebaseAuth.instance.currentUser?.displayName;
    final members =
        all_contacts.value["contacts"][all_contacts.value["contacts"]
            .indexWhere((e) => e['chat_id'] == chatId)]["members"];

    Map<String, dynamic> seen_data = {};
    for (final i in members) {
      seen_data[i] = sender == i ? true : false;
    }

    await _db.from('messages').insert({
      'chat_id': chatId,
      'sender_id': sender,
      "sender_prof_pic": profpic,
      'receiver_id': "",
      "sender_name": name,
      "type": type,
      "members": members,
      "msg_seen": seen_data,
      'msg': msg,
      "embedding":embed
    });

    await _db
        .from('user_contacts')
        .update({
          'last_msg': msg,
          "last_msg_time": DateTime.now().toUtc().toIso8601String(),
          "msg_seen": seen_data,
        })
        .eq('chat_id', chatId);
    // print("fetching fcm 😋 ");
    // final fcmToken = await contact["fcm_token"];
    // print("😋😋😋 fcm token :${fcmToken}");
    // if (fcmToken != null && fcmToken.isNotEmpty) {
    //   Future.microtask(() {
    //     http.post(
    //       Uri.parse(notificationServerUrl),
    //       headers: {'Content-Type': 'application/json'},
    //       body: jsonEncode({
    //         'token': fcmToken,
    //         'title': FirebaseAuth.instance.currentUser?.displayName,
    //         'body': msg.contains('\uE000') ? '⦿ Image' : msg,
    //         'send_id': sender,
    //       }),
    //     );
    //   });
    // }
  }

  ////  chat between user and contact  /////

  Future<Map<String, dynamic>> getChat(
    String chatId,
  ) async {
    String currentUser = FirebaseAuth.instance.currentUser!.email??"";
    final rows = await _db
        .from('messages')
        .select('msg,timestamp,sender_id,receiver_id,conversation_id,chat_id,sender_name,sender_prof_pic,type,msg_seen')
        .eq("chat_id", chatId)
        .contains('members', [currentUser])
        .order('timestamp', ascending: true);
    final List<Map<String, dynamic>> messages = rows.map((m) {
      final sender = m['sender_id'] as String;
    

      return {
        'msg': m['msg'],
        "sender_prof_pic":
            m["sender_prof_pic"] ??
            "https://qbppenfcbrszswmfmiop.supabase.co/storage/v1/object/public/images/uploads/1771249136595.jpg",
        'receiver_id': m['receiver_id'],
        "sender_name": m['sender_name'],
        'sender_id': m['sender_id'],
        'timestamp': m['timestamp'],
        'conversation_id': m['conversation_id'],
        "chat_id": m["chat_id"],
        'user_sent': sender == currentUser ? 'yes' : 'no',
        "type": m["type"],
        "msg_seen" :m["msg_seen"]
      };
    }).toList();
    return {
      'chat': {
        'chat_id': chatId,
        'message_count': messages.length,
        'messages': messages,
      },
    };
  }

  ////  user all chats ////

  Future<Map<String, dynamic>> getAllChatsFormatted(String userId) async {
    final rows = await _db
        .from('messages')
        .select(
          'msg,timestamp,sender_id,receiver_id,conversation_id,chat_id,sender_name,sender_prof_pic,type,msg_seen',
        )
        .or('members.cs.{${userId}}',
        // .or(
        //   'sender_id.eq.$userId,receiver_id.eq.$userId,members.cs.{${userId}}',
        )
        .order('timestamp', ascending: true);
    final Map<String, List<Map<String, dynamic>>> chatMap = {};

    for (final m in rows) {
      final sender = m['sender_id'] as String;
      final chatid = m["chat_id"] as String;
      chatMap.putIfAbsent(chatid, () => []);
      chatMap[chatid]!.add({
        'msg': m['msg'],
        "sender_prof_pic":
            m["sender_prof_pic"] ??
            "https://qbppenfcbrszswmfmiop.supabase.co/storage/v1/object/public/images/uploads/1771249136595.jpg",
        'receiver_id': m['receiver_id'],
        "sender_name": m['sender_name'],
        'sender_id': m['sender_id'],
        'timestamp': m['timestamp'],
        'conversation_id': m['conversation_id'],
        "chat_id": m["chat_id"],
        'user_sent': sender == userId ? 'yes' : 'no',
        "type": m["type"],
        "msg_seen" :m["msg_seen"]
      });
    }
    final Map<String, dynamic> chats ={};

    chatMap.forEach((chatid, messages) {
      chats["$chatid"]={
        'chat_id': chatid,
        'message_count': messages.length,
        'messages': messages,
      };});
    
    return {'chats': chats};
  }

  ////// add members to group /////
  Future<void> add_member_to_group(String newUserId, String chatId) async {
    final data = await _db
        .from('user_contacts')
        .select('members')
        .eq('chat_id', chatId)
        .single();

    List<String> members = List<String>.from(data['members']);
    if (!members.contains("chatbot")) members.add("chatbot");
    if (!members.contains(newUserId)) {
      members.add(newUserId);
      print(members);
      await _db
          .from('user_contacts')
          .update({'members': members})
          .eq('chat_id', chatId);
    }
    print("Done Adding 🛰️🛰️🛰️🛰️🚀🚀 ");
  }

  //////   remove member from group /////
  Future<void> remove_member_from_group(String newUserId, String chatId) async {
    final data = await _db
        .from('user_contacts')
        .select('members')
        .eq('chat_id', chatId)
        .single();

    Set<String> members = Set<String>.from(data['members']);
    if (members.contains(newUserId)) {
      members.remove(newUserId);
      print(members);
      await _db
          .from('user_contacts')
          .update({'members': members.toList()})
          .eq('chat_id', chatId);
    }
    print("Done Removing 🛰️🛰️🛰️🛰️🚀🚀 ");
  }

  /////  add members to group while creating  /////
  Future<void> create_group(
    List users,
    String name,
    String pic,
    String chatId,
  ) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    List<dynamic> members = List.from(users);
    if (!members.contains("chatbot")) members.add("chatbot");
    if (!members.contains(email)) members.add(email);
    print("\n  \n  \n");
    print(members);
    await _db.from('user_contacts').insert({
      "members": members,
      "profile_pic": pic,
      "name": name,
      "group": true,
      "chat_id": chatId,
    });
    print("Done Adding 🛰️🛰️🛰️🛰️🚀🚀 ");
  }

  ////  delete message ////
  Future<void> deleteSingleMessage(String chatId, int convoId) async {
    await _db
        .from('messages')
        .delete()
        .eq('conversation_id', convoId)
        .eq('chat_id', chatId);
    print("object");
  }

  ///// delete for user only   ////
  Future<void> deleteMsgforuser(String chatId, int convoId) async {
    final List<dynamic> members = [];
    String User = FirebaseAuth.instance.currentUser!.email??"";
    final response = await _db.from("messages").select("members").eq("chat_id", chatId).eq("conversation_id", convoId);
    for(final i in response[0]["members"]){
      if(i!=User)
      members.add(i);
    }
    await _db.from("messages").update({"members":members}).eq("chat_id",chatId).eq("conversation_id",convoId);
    print(members);
  }

  ////   clear chat  /////

  Future<void> clearChat(String chatId) async {
    await _db
        .from('messages')
        .delete()
        .eq("chat_id", chatId)
        .gt('conversation_id', 0);
  }

  /////  search users  /////

  Future<List> searchUsers(String query) async {
    return await _db
        .from('users')
        .select('user_id,name,profile_pic')
        .or('user_id.ilike.%$query%,name.ilike.%$query%');
  }

  /////  get user fcm token /////

  Future<String?> getUserToken(String userId) async {
    final r = await _db
        .from('users')
        .select('fcm_token')
        .eq('user_id', userId)
        .maybeSingle();
    return r?['fcm_token'];
  }

  /////  get all stored fcm tokens  /////

  Future<List> allTokens() async {
    return await _db.from('users').select('user_id,fcm_token');
  }

  /////  upload image base64 string to database  ////

  Future<String> uploadImageBase64(String base64Image) async {
    final bytes = base64Decode(base64Image.split(',').last);
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    print('UPLOAD START');
    await _db.storage
        .from('images')
        .uploadBinary('uploads/$name', Uint8List.fromList(bytes));
    print('UPLOAD DONE');
    return _db.storage.from('images').getPublicUrl('uploads/$name');
  }
}
