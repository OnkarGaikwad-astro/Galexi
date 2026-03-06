import 'dart:convert';

import 'package:Aera/chat_page.dart';
import 'package:Aera/create_group.dart';
import 'package:Aera/essentials/colours.dart';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/home_page.dart';
import 'package:Aera/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

bool isdark = true;

class AddContact extends StatefulWidget {
  const AddContact({super.key});
  @override
  State<AddContact> createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {
  Map<String, dynamic> result = {"count": 0, "users": []};
  TextEditingController searchq = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetch_all_users();
  }

  void filterList() async {
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

  void showAddingContactPopup(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: kDivider,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Text(text, style: GoogleFonts.josefinSans(fontSize: 15)),
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
        // backgroundColor: isdark ? kSentMessage : kTextHint,
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            print(result);
          },
          child: Text(
            "Add Contacts",
            style: GoogleFonts.josefinSans(letterSpacing: 2),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal:8.0),
                child: Container(
                  height: 50,
                  // width: 370,
                  width: double.maxFinite,
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
                        style: GoogleFonts.josefinSans(
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                      fillColor: kDivider,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          strokeAlign: BorderSide.strokeAlignCenter,
                          color: kTextHint,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          strokeAlign: BorderSide.strokeAlignCenter,
                          color: kTextHint,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          strokeAlign: BorderSide.strokeAlignCenter,
                          color: kTextHint,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateGroup()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: kTextHint,
                    ),
                    height: 50,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: kPrimaryVariant,
                            ),
                            child: Icon(Icons.group_add_outlined),
                          ),
                        ),
                        SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Create an Group .",
                            style: GoogleFonts.josefinSans(fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 0,
                  bottom: 8,
                ),
                child: InkWell(
                  onTap: () async {
                    show_options();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: kTextHint,
                    ),
                    height: 50,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: kPrimaryVariant,
                            ),
                            child: Icon(Icons.group_add_rounded),
                          ),
                        ),
                        SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Join a Group via Code .",
                            style: GoogleFonts.josefinSans(fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: result["count"] == null
                    ? [
                        SizedBox(height: 100),
                        LottieBuilder.asset("assets/lotties/hello.json"),
                      ]
                    : (result["count"] == 0
                          ? [
                              SizedBox(height: 200),
                              LottieBuilder.asset(
                                "assets/lotties/loader_cat.json",
                              ),
                            ]
                          : List.generate(result["count"], (index) {
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

  void show_options() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController jcode = TextEditingController();
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/girl.jpg"),
                fit: BoxFit.cover,
              ),
              color: kTextHint,
              borderRadius: BorderRadius.circular(28),
            ),
            height: 180,
            // width: 150,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  SizedBox(height: 18),
                  TextField(
                    controller: jcode,
                    cursorColor: isdark
                        ? const Color.fromARGB(255, 122, 218, 238)
                        : kPrimaryVariant,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.label_important_outlined,
                        size: 25,
                      ),
                      hint: Text(
                        "Enter Code .",
                        style: GoogleFonts.josefinSans(
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                      fillColor: kDivider,
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
                  Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: SizedBox(height: 15),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(15),
                      ),
                      elevation: 20,
                      backgroundColor: kInputBorder,
                    ),
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      if (jcode.text != "") {
                        showAddingContactPopup(context, "Joining Group ...");
                        final userid =
                            await FirebaseAuth.instance.currentUser?.email;
                        await chatApi.add_member_to_group(userid!, jcode.text);
                        await user_contact();
                        print("🚀🚀🚀🚀🚀 Joined");
                         Navigator.pop(context);
                         Navigator.pop(context);
                         Navigator.pop(context);
                      }
                    },
                    child: Text(
                      "Join Group ",
                      style: GoogleFonts.josefinSans(
                        color: const Color.fromARGB(255, 190, 217, 255),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
            showAddingContactPopup(context, "Adding contact…");
            await Add_user_contact(num);
            await user_contact();
            print("done adding");
            Navigator.pop(context);
            Navigator.pop(context);
          },
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
                  // width: 230,
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
                                  style: GoogleFonts.josefinSans(
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
                        child: Text(
                          style: GoogleFonts.josefinSans(color: Colors.grey),
                          result["users"][num]["user_id"],
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
