import 'package:flutter/material.dart';

String master_url = "https://messenger-api-86895289380.asia-south1.run.app/";


ValueNotifier<Map<String, dynamic>> all_contacts =
    ValueNotifier(<String, dynamic>{});

ValueNotifier<Map<String, dynamic>> all_msg_list =
    ValueNotifier(<String, dynamic>{});

ValueNotifier<Map<String, dynamic>> all_users_ =
    ValueNotifier(<String, dynamic>{});
