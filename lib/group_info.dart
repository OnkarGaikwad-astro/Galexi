import 'dart:convert';
import 'dart:io';

import 'package:Aera/chat_page.dart';
import 'package:Aera/essentials/colours.dart';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/home_page.dart';
import 'package:Aera/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupInfo extends StatefulWidget {
  final chatId;
  GroupInfo({super.key, required this.chatId});

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> memberinfo = [];
  late String name_change;
  bool readonly = true;
  bool img_uploaded = true;
  final TextEditingController namechange = TextEditingController();
  File? selectedImage;
  @override
  void initState() {
    super.initState();
    initdata();
  }

  ////  initialize data  ///
  Future<void> initdata() async {
    data = await chatApi.getGroupMembers(widget.chatId);
    setState(() {});
    memberinfo = await Supabase.instance.client.from("users").select("name,profile_pic,user_id").inFilter("user_id", data[0]["members"]);
    setState(() {
    });
    print(memberinfo);
  }

  @override
  Widget build(BuildContext context) {
    namechange.text = data.length != 0 ? data[0]["name"] : "";
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () async {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(35),
              child: Container(
                color: const Color.fromARGB(99, 92, 106, 130),
                height: 150,
                width: 150,
                child: data.length != 0
                    ? CachedNetworkImage(
                        filterQuality: FilterQuality.high,
                        imageUrl: data[0]["profile_pic"],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              padding: EdgeInsets.all(5),
                              color: Colors.black,
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image),
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                      )
                    // : Image.asset(
                    //     "assets/images/interstellar.jpg",
                    //     fit: BoxFit.cover,
                    //   ),
                    : CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                        padding: EdgeInsets.all(60),
                      ),
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    final File? image = await pickImageFromGallery();
                    if (image != null) {
                      setState(() {
                        selectedImage = image;
                        img_uploaded = false;
                      });
                    }
                    final bytes = await selectedImage!.readAsBytes();
                    final url = await chatApi.uploadImageBase64(
                      base64Encode(bytes),
                    );

                    print(url);
                    await Supabase.instance.client
                        .from("user_contacts")
                        .update({"profile_pic": url})
                        .eq("chat_id", widget.chatId);
                    img_uploaded = true;
                    initdata();
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(15),
                    ),
                    backgroundColor: const Color.fromARGB(255, 58, 83, 134),
                    elevation: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      !img_uploaded
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1,
                              ),
                            )
                          : Icon(
                              Icons.edit,
                              size: 25,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                      SizedBox(width: 9),
                      Text(
                        "Change Profile Pic",
                        style: GoogleFonts.josefinSans(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      // width: 210,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        color: const Color.fromARGB(118, 110, 156, 176),
                      ),
                      child: Center(
                        child: TextField(
                          // textAlign: TextAlign.center,
                          style: GoogleFonts.josefinSans(
                            // color: const Color.fromARGB(255, 223, 255, 224),
                            fontSize: 20,
                          ),
                          cursorColor: Colors.teal,
                          maxLines: 1,
                          enabled: true,
                          readOnly: readonly,
                          controller: namechange,
                          decoration: InputDecoration(
                            // filled: true,
                            isDense: true,
                            prefixIcon: IconButton(
                              onPressed: () async {
                                readonly = !readonly;

                                setState(() {});
                              },
                              icon: Icon(
                                Icons.mode_edit_outline_outlined,
                                // color: const Color.fromARGB(181, 120, 253, 239),
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(0, 255, 255, 255),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 7,
                      backgroundColor: const Color.fromARGB(255, 58, 83, 134),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(15),
                      ),
                    ),
                    onPressed: () async {
                      print(readonly);
                      await Supabase.instance.client
                          .from("user_contacts")
                          .update({"name": namechange.text})
                          .eq("chat_id", widget.chatId);
                      initdata();
                      readonly = true;
                    },
                    child: Icon(
                      Icons.task_alt,
                      color: const Color.fromARGB(255, 82, 255, 160),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentGeometry.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0,top: 20,bottom: 5),
                child: Text("Group Members (${memberinfo.length})",style: GoogleFonts.josefinSans(fontSize: 20),),
              ),
            ),
            (memberinfo.length == 0) ? 
              LottieBuilder.asset("assets/lotties/loader_cat.json")
            :Expanded(
              child: ListView.builder(
                itemCount: memberinfo.length ,
                itemBuilder: (context,index) {
                  return chat_list(index) ;
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  backgroundColor: const Color.fromARGB(148, 192, 228, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(15),
                  ),
                ),
                onPressed: () async {
                  final user = await FirebaseAuth.instance.currentUser!.email ?? "";
                  await chatApi.remove_member_from_group(user, widget.chatId);
                  initdata();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  "Exit Group !",
                  style: GoogleFonts.josefinSans(
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(215, 248, 3, 3),
                  ),
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  ///// image picker /////
  Future<File?> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      imageQuality: 20,
      source: ImageSource.gallery,
    );
    if (image != null) {
      return File(image.path);
    }
    return null;
  }


  Future<void> user_contacts() async {
    final email = await FirebaseAuth.instance.currentUser?.email;
    final a = await chatApi.getUserContacts(email!);
    all_contacts.value = a;
    final box = Hive.box('cache');
    box.put('all_contacts', all_contacts.value);
    setState(() {});
  }
  
  /////   chat list widget  ////
  Widget chat_list(int num) {
    final  user = memberinfo[num];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: ()async {
            // HapticFeedback.heavyImpact();
            // final person =await FirebaseAuth.instance.currentUser!.email ?? "";
            // showAddingContactPopup(context, "Adding contact…");
            // await chatApi.addContact(person, user["user_id"]);
            // print("done adding");
            // user_contacts();
            // Navigator.pop(context);
            // Navigator.pop(context);
            // Navigator.pop(context);
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
                  child: Hero(
                    tag: user["user_id"],
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      maxRadius: 23,
                      backgroundImage: NetworkImage(
                        user["profile_pic"]
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: SizedBox(
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
                                    user["name"],
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
                            style: GoogleFonts.josefinSans(color: const Color.fromARGB(255, 197, 197, 197)),
                            user["user_id"],
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(onPressed: () async{
                   HapticFeedback.heavyImpact();
            final person =await FirebaseAuth.instance.currentUser!.email ?? "";
            showAddingContactPopup(context, "Adding contact…");
            await chatApi.addContact(person, user["user_id"]);
            print("done adding");
            await user_contacts();
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ChatPage(ID: user["user_id"]);
            },));
                }, icon: Icon(Icons.message_rounded))
              ],
            ),
          ),
        ),
      ),
    );
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

}
