import 'dart:io';
import 'package:chat_firebase/components/text_compose.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import "package:flutter/material.dart";
import 'package:image_picker/image_picker.dart';

class Message {
  String? text;
  String? imgUrl;

  Message.fromData(Map data)
      : text = data["text"],
        imgUrl = data["imgUrl"];
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  void _sendMessage({String? text, XFile? file}) async {
    Map<String, dynamic> data = {};
    if (file != null) {
      UploadTask task = FirebaseStorage.instance
          .ref()
          .child(DateTime.now().microsecondsSinceEpoch.toString())
          .putFile(File(file.path));
      TaskSnapshot snapshot = await task;
      String url = await snapshot.ref.getDownloadURL();
      data['imgUrl'] = url;
    }
    if (text != null) {
      data["text"] = text;
    }
    FirebaseFirestore.instance.collection("mensagens").add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ola"),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("mensagens")
                  .snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> documents = snapshot.data!.docs;
                    return ListView.builder(
                        itemCount: documents.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          var data = documents[index].data();

                          print(data!["text"]);

                          return ListTile(
                            title: Text("a"),
                          );
                        });
                }
              },
            ),
          ),
          TextCompose(
            sendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }
}
