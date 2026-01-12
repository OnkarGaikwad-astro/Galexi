import 'package:flutter/material.dart';

String master_url = "https://vercel-server-ivory-six.vercel.app/";

ValueNotifier<Map<String, dynamic>> all_contacts =
    ValueNotifier(<String, dynamic>{});

ValueNotifier<Map<String, dynamic>> all_msg_list =
    ValueNotifier(<String, dynamic>{});

ValueNotifier<Map<String, dynamic>> all_users_ =
    ValueNotifier(<String, dynamic>{});
