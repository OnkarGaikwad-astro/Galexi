import 'dart:convert';

import 'package:Aera/chat_page.dart';
import 'package:Aera/essentials/colours.dart';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/home_page.dart';
import 'package:Aera/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

bool isdark = true;


class AddContact extends StatefulWidget {
  const AddContact({super.key});
  @override
  State<AddContact> createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {

  Map<String, dynamic> result = {
    "count" : 0,"users" : []
  };
  TextEditingController searchq = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetch_all_users();
  }

void filterList() async{
  String query = searchq.text.toLowerCase();
  result["users"] = await chatApi.searchUsers(query);
  result["count"] = result["users"].length;
  setState(() {});
}

Future<void> fetch_all_users() async {
  final data = await chatApi.getAllUsers();
  setState(() {
    result = data;
  });
}

void showAddingContactPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            const Text(
              "Adding contact…",
              style: TextStyle(fontFamily: "cursive",fontSize: 15),
            ),
          ],
        ),
      ),
    ),
  );
}


  //////  add contact  ////
  Future<void> Add_user_contact(int num) async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    print(email);
    print(result["users"][num]["user_id"]);
    final a = await chatApi.addContact(email!, result["users"][num]["user_id"]);
    print("🚀 ${a}");
    print("\n");
    print("\n");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(onTap: () {
          print(result);
        },child: Text("Add Contacts",style: TextStyle(letterSpacing: 2,fontFamily: "times new roman"),)),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(height: 50,
              width: 370,
                child: TextField(
                  controller: searchq,
                  onChanged: (value) {
                    filterList();
                  },
                  cursorColor: isdark
                      ? const Color.fromARGB(255, 122, 218, 238)
                      : kPrimaryVariant,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 25),
                    hint: Text(
                      "Find a star to chat with.....",
                      style: TextStyle(
                        letterSpacing: 2,
                        fontFamily: "times new roman",
                      ),
                    ),
                    fillColor: const Color.fromARGB(104, 158, 158, 158),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: kTextPrimary,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: kTextPrimary,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: kTextPrimary,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: result["count"]==null?[SizedBox(height: 100,),LottieBuilder.asset("assets/lotties/hello.json")]:(result["count"] == 0? [SizedBox(height: 200,),LottieBuilder.asset("assets/lotties/loader_cat.json")] : List.generate(result["count"], (index) {
                  return chat_list(index);
                })),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //////  refresh contacts  ////
  Future<void> user_contact() async {
    await appKey.currentState?.user_contacts();
  }

  Widget chat_list(int num) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          splashColor: Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(200, 255, 255, 255)
              : const Color.fromARGB(189, 0, 0, 0),
          borderRadius: BorderRadius.circular(15),

          onTap: () async {
            print("object");
            showAddingContactPopup(context);
            await Add_user_contact(num);
            await user_contact();
            print("done adding");
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: Hero(
            tag: result["users"][num]["name"],
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: chat_color,
              ),
              width: double.infinity,
              height: 60,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      maxRadius: 23,
                      backgroundImage: NetworkImage(
                        result["users"][num]["profile_pic"],
                      ),
                    ),
                  ),
                  SizedBox(width: 9),
                  SizedBox(
                    width: 230,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 300,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 210,
                                  child: Text(
                                    result["users"][num]["name"],
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: "times new roman",
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          child: Text(style: TextStyle(color: Colors.grey),result["users"][num]["user_id"],softWrap: true,overflow: TextOverflow.ellipsis,),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
