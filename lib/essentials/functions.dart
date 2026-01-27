import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:Aera/essentials/data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseChatApi {
  final SupabaseClient _db = Supabase.instance.client;
  final String notificationServerUrl;
  SupabaseChatApi({required this.notificationServerUrl});
  String _istNow() =>
      DateFormat('yyyy-MM-dd \n HH:mm:ss').format(DateTime.now());

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

  /////  get last seen  /////

  Future<String?> getLastSeen(String userId) async {
    final r = await _db
        .from('users')
        .select('last_seen')
        .eq('user_id', userId)
        .maybeSingle();
    return r?['last_seen'];
  }

  /////  mark msg seen  ////

  Future<String> markLastMsgSeen(String userId, String otherUser) async {
    final rows = await _db
        .from('messages')
        .select('id,sender_id,receiver_id')
        .or(
          'and(sender_id.eq.$otherUser,receiver_id.eq.$userId),'
          'and(sender_id.eq.$userId,receiver_id.eq.$otherUser)',
        )
        .order('timestamp', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      return 'no_messages';
    }
    final lastMsg = rows.first;
    final msgId = lastMsg['id'];
    final sender = lastMsg['sender_id'];
    final receiver = lastMsg['receiver_id'];
    if (userId != receiver) {
      return 'no_update_user_is_sender';
    }
    await _db.from('messages').update({'msg_seen': 'seen'}).eq('id', msgId);

    return 'last_message_marked_seen';
  }

  /////  add contact /////

  Future<Map<String, dynamic>> addContact(
    String userId,
    String contactId,
  ) async {
    final existing = await _db
        .from('user_contacts')
        .select('id')
        .eq('user_id', userId)
        .eq('contact_id', contactId)
        .maybeSingle();
    if (existing != null) {
      return {'status': 'already_exists'};
    }
    await _db.from('user_contacts').insert({
      'user_id': userId,
      'contact_id': contactId,
    });
    addMessageFast(userId, contactId, "");
    return {'status': 'contact_added'};
  }

  ////  get user contacts list  /////

  Future<Map<String, dynamic>> getUserContacts(String userId) async {
    final manualRows = await _db
        .from('user_contacts')
        .select('contact_id')
        .eq('user_id', userId);
    final manualSet = <String>{
      for (final r in manualRows) r['contact_id'] as String,
    };
    final msgRows = await _db
        .from('messages')
        .select('sender_id,receiver_id,msg,msg_seen,timestamp')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('timestamp', ascending: false);
    final Map<String, Map<String, dynamic>> contactMap = {};
    for (final msg in msgRows) {
      final sender = msg['sender_id'] as String;
      final receiver = msg['receiver_id'] as String;
      final other = sender == userId ? receiver : sender;
      if (!contactMap.containsKey(other)) {
        contactMap[other] = {
          'id': other,
          'last_message': msg['msg'],
          'last_message_time': msg['timestamp'],
          'last_message_sender_id': sender,
          'msg_seen': sender == userId ? 'seen' : (msg['msg_seen'] ?? ''),
        };
      }
    }
    for (final id in manualSet) {
      contactMap.putIfAbsent(
        id,
        () => {
          'id': id,
          'last_message': '',
          'last_message_time': '',
          'last_message_sender_id': '',
          'msg_seen': '',
        },
      );
    }
    if (contactMap.isEmpty) {
      return {'contact_count': 0, 'contacts': []};
    }
    final ids = contactMap.keys.join(',');
    final userRows = await _db
        .from('users')
        .select('user_id,name,profile_pic,bio,fcm_token')
        .inFilter('user_id', contactMap.keys.toList());
    final List<Map<String, dynamic>> contacts = [];
    for (final u in userRows) {
      final uid = u['user_id'];
      final info = contactMap[uid]!;
      contacts.add({
        'id': uid,
        'name': u['name'] ?? '',
        'profile_pic': u['profile_pic'] ?? '',
        'bio': u['bio'] ?? '',
        'fcm_token': u['fcm_token'],
        'last_message': info['last_message'],
        'last_message_time': info['last_message_time'],
        'last_message_sender_id': info['last_message_sender_id'],
        'msg_seen': info['msg_seen'],
      });
    }
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
          'and(user_id.eq.$u1,contact_id.eq.$u2),and(user_id.eq.$u2,contact_id.eq.$u1)',
        );
  }

  Future<String?> _findChat(String a, String b) async {
    final r = await _db
        .from('messages')
        .select('id')
        .or(
          'and(sender_id.eq.$a,receiver_id.eq.$b),and(sender_id.eq.$b,receiver_id.eq.$a)',
        )
        .limit(1);
    return r.isEmpty ? null : r.first['id'];
  }

  /////  add message   /////
String buildChatId(String a, String b) {
  final pair = [a, b]..sort();
  return pair.join("__");
}

Future<void> addMessageFast(
  String sender,
  String receiver,
  String msg,
) async {
  final chat = all_msg_list.value["chats"].firstWhere(
    (c) => c["contact_id"] == receiver,
    orElse: () => {"message_count": 0},
  );

  final chatId = buildChatId(sender, receiver);
  final convoId = chat["message_count"] + 1;
  await _db.from('messages').insert({
    'id': chatId,
    'conversation_id': convoId,
    'sender_id': sender,
    'receiver_id': receiver,
    'msg': msg,
    'timestamp': _istNow(),
  });
  final contact = all_contacts.value["contacts"].firstWhere(
    (c) => c["id"] == receiver,
  );

  print("fetching fcm 😋 ");
  final fcmToken = await contact["fcm_token"];
  print("😋😋😋 fcm token :${fcmToken}");
  if (fcmToken != null && fcmToken.isNotEmpty) {
    Future.microtask(() {
      http.post(
        Uri.parse(notificationServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title':FirebaseAuth.instance.currentUser?.displayName, 
          'body': msg.contains('\uE000') ? '⦿ Image' : msg,
          'send_id': sender,
        }),
      );
    });
  }
}


  ////  chat between user and contact  /////

  Future<Map<String, dynamic>> getChat(
    String currentUser,
    String otherUser,
  ) async {
    final rows = await _db
        .from('messages')
        .select('msg,timestamp,sender_id,receiver_id')
        .or(
          'and(sender_id.eq.$currentUser,receiver_id.eq.$otherUser),'
          'and(sender_id.eq.$otherUser,receiver_id.eq.$currentUser)',
        )
        .order('conversation_id');
    final List<Map<String, dynamic>> messages = rows.map((m) {
      final sender = m['sender_id'] as String;
      return {
        'msg': m['msg'],
        'receiver_id': m['receiver_id'],
        'sender_id': sender,
        'timestamp': m['timestamp'],
        'user_sent': sender == currentUser ? 'yes' : 'no',
      };
    }).toList();
    return {
      'chat': {
        'contact_id': otherUser,
        'message_count': messages.length,
        'messages': messages,
      },
    };
  }

  ////  user all chats ////

  Future<Map<String, dynamic>> getAllChatsFormatted(String userId) async {
    final rows = await _db
        .from('messages')
        .select('msg,timestamp,sender_id,receiver_id,conversation_id')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('timestamp', ascending: true);
    final Map<String, List<Map<String, dynamic>>> chatMap = {};
    for (final m in rows) {
      final sender = m['sender_id'] as String;
      final receiver = m['receiver_id'] as String;
      final otherUser = sender == userId ? receiver : sender;
      chatMap.putIfAbsent(otherUser, () => []);
      chatMap[otherUser]!.add({
        'msg': m['msg'],
        'receiver_id': receiver,
        'sender_id': sender,
        'timestamp': m['timestamp'],
        'conversation_id': m['conversation_id'],
        'user_sent': sender == userId ? 'yes' : 'no',
      });
    }
    final List<Map<String, dynamic>> chats = [];
    chatMap.forEach((contactId, messages) {
      chats.add({
        'contact_id': contactId,
        'message_count': messages.length,
        'messages': messages,
      });
    });
    return {'chats': chats};
  }

  ////  delete message ////
Future<void> deleteSingleMessage(
  String u1,
  String u2,
  int convoId,
) async {
  final chatId = buildChatId(u1, u2); // same chat id logic you use

  await _db.rpc(
    'delete_and_renumber',
    params: {
      'chat_id': chatId,
      'convo': convoId,
    },
  );
}


  ////   clear chat  /////

  Future<void> clearChat(String a, String b) async {
    await _db
        .from('messages')
        .delete()
        .or(
          'and(sender_id.eq.$a,receiver_id.eq.$b),and(sender_id.eq.$b,receiver_id.eq.$a)',
        )
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
