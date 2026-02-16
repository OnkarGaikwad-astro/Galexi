import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:Aera/chat_page.dart';
import 'package:Aera/essentials/colours.dart';
import 'package:Aera/essentials/data.dart';
import 'package:Aera/home_page.dart';
import 'package:Aera/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

bool isdark = true;

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key});
  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  Map<String, dynamic> result = {"count": 0, "users": []};
  TextEditingController searchq = TextEditingController();
  TextEditingController grpname = TextEditingController();
  File? selectedImage;
  bool imguploading = false;
  String imgurl = "";

  List<dynamic> selectedItems = [];

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

  ///// generate random group chat id  //////

  String generateGroupId({int length = 8}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random.secure();
    return List.generate(length, (index) {
      return chars[random.nextInt(chars.length)];
    }).join();
  }

  //////  add members  ////

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
            "Create Group",
            style: GoogleFonts.josefinSans(letterSpacing: 2),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 0,
                  bottom: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: kTextHint,
                  ),
                  height: 70,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: kPrimaryVariant,
                          ),
                          child: Material(
                            color: kPrimaryVariant,
                            borderRadius: BorderRadius.circular(15),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              splashColor: kInputBorder,
                              onTap: () async {
                                HapticFeedback.heavyImpact();
                                print(selectedImage == null);
                                selectedImage = await pickImageFromGallery();
                                imguploading = true;
                                setState(() {});
                                if (selectedImage != null)
                                  await uploadImageBase64(selectedImage!);
                                imguploading = false;
                                setState(() {});
                                print(selectedImage == null);
                              },
                              child: imgurl == ""
                                  ? Icon(Icons.wallpaper_rounded)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: imgurl,
                                        fit: BoxFit.cover,
                                        fadeInDuration: Duration.zero,
                                        fadeOutDuration: Duration.zero,

                                        placeholder: (context, url) => Center(
                                          child: SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: isdark
                                                  ? Colors.white
                                                  : Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.broken_image),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 5.0,
                          right: 8,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Container(
                          height: 54,
                          width: 289,
                          child: TextField(
                            controller: grpname,
                            cursorColor: isdark
                                ? const Color.fromARGB(255, 122, 218, 238)
                                : kPrimaryVariant,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.double_arrow_rounded,
                                size: 25,
                                color: isdark ? Colors.white : Colors.black,
                              ),
                              hint: Text(
                                "Enter Group Name...",
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
                                borderRadius: BorderRadius.circular(15),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  strokeAlign: BorderSide.strokeAlignCenter,
                                  color: kTextPrimary,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  strokeAlign: BorderSide.strokeAlignCenter,
                                  color: kTextPrimary,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 6,
                  top: 8,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: kTextHint,
                      ),
                      height: 50,
                      width: 240,
                      child: Material(
                        borderRadius: BorderRadius.circular(15),
                        color: kTextHint,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          splashColor: kInputBackground,
                          onTap: () async {
                            HapticFeedback.heavyImpact();
                            print(selectedImage == null);
                            selectedImage = await pickImageFromGallery();
                            imguploading = true;
                            setState(() {});
                            if (selectedImage != null)
                              await uploadImageBase64(selectedImage!);
                            imguploading = false;
                            setState(() {});
                            print(selectedImage == null);
                          },
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
                                  child: imguploading
                                      ? CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: isdark
                                              ? Colors.white
                                              : Colors.black,
                                          padding: EdgeInsets.all(10),
                                        )
                                      : Icon(
                                          Icons.file_upload_outlined,
                                          color: isdark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                ),
                              ),
                              // SizedBox(width: 6,),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Upload Profile Image",
                                  style: GoogleFonts.josefinSans(
                                    fontSize: 14,
                                    color: isdark ? Colors.white : Colors.black,
                                  ),
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
                        top: 8,
                        bottom: 8,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        height: 50,
                        child: Material(
                          borderRadius: BorderRadius.circular(15),
                          color: kTextHint,
                          child: Center(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              splashColor: kInputBackground,
                              onTap: () async {
                                chatId = generateGroupId();
                                HapticFeedback.heavyImpact();
                                if (imgurl == "" ||
                                    grpname.text == "" ||
                                    selectedItems == [])
                                  return;
                                showAddingContactPopup(
                                  context,
                                  "Creating Group...",
                                );
                                await chatApi.create_group(
                                  selectedItems.toList(),
                                  grpname.text,
                                  imgurl,
                                  chatId,
                                );
                                await user_contact();
                                Navigator.pop(context);
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
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
                                      child: Icon(
                                        Icons.task_alt,
                                        color:Color.fromARGB(255, 83, 247, 88),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 10.0,
                                      top: 8,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      "Done",
                                      style: GoogleFonts.josefinSans(
                                        fontSize: 17,
                                        color: isdark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 50,
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
                      "Search among the stars.....",
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
              ),
              SizedBox(height: 10),
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

  ///// image picker ///
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

  /////  upload image to cloud ////
  Future<void> uploadImageBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final url = await chatApi.uploadImageBase64(base64Encode(bytes));
    print("\n");
    print("🚀url 📷${url}");
    print("\n");
    imgurl = url;
    setState(() {});
  }

  /////   chat list widget  ////
  Widget chat_list(int num) {
    bool is_selected = selectedItems.contains(result["users"][num]["user_id"]);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            HapticFeedback.heavyImpact();
            print("changed");
            if (is_selected) {
              selectedItems.remove(result["users"][num]["user_id"]);
            } else {
              selectedItems.add(result["users"][num]["user_id"]);
            }
            setState(() {});
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
                Checkbox(
                  value: is_selected,
                  onChanged: (value) {
                    HapticFeedback.heavyImpact();
                    print("changed");
                    if (is_selected) {
                      selectedItems.remove(result["users"][num]["user_id"]);
                    } else {
                      selectedItems.add(result["users"][num]["user_id"]);
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
