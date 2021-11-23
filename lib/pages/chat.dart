import 'dart:io';
import 'package:chat_firebase/components/chat_message.dart';
import 'package:chat_firebase/components/text_compose.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import "package:flutter/material.dart";
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

class Message {
  String? text;
  String? imgUrl;
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.userChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<User?> _getUser() async {
    if (_currentUser != null) return _currentUser;
    try {
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        throw Error();
      }
      final GoogleSignInAuthentication authentication =
          await account.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
      );
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;
      return user;
    } catch (error) {
      return null;
    }
  }

  void _sendMessage({String? text, XFile? file}) async {
    final User? user = await _getUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possivel fazer o login tente novamente!'),
        backgroundColor: Colors.red,
      ));
    }
    Map<String, dynamic> data = {
      "uuid": user!.uid,
      "sender": user.displayName,
      "senderPhotoUrl": user.photoURL,
      "time": Timestamp.now()
    };
    if (file != null) {
      setState(() {
        _isLoading = true;
      });
      UploadTask task = FirebaseStorage.instance
          .ref()
          .child(
              "${_currentUser?.uid}-${DateTime.now().microsecondsSinceEpoch.toString()}")
          .putFile(File(file.path));
      TaskSnapshot snapshot = await task;
      String url = await snapshot.ref.getDownloadURL();
      data['imgUrl'] = url;
      setState(() {
        _isLoading = false;
      });
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
        title: Text(_currentUser != null
            ? "Ola, ${_currentUser!.displayName}"
            : "Chat App"),
        elevation: 0,
        centerTitle: true,
        actions: [
          _currentUser != null
              ? IconButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Voce saiu com sucesso.'),
                    ));
                  },
                  icon: Icon(Icons.exit_to_app))
              : Container()
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentUser != null
                ? StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("mensagens")
                        .orderBy("time")
                        .snapshots(),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                        case ConnectionState.waiting:
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        default:
                          List<DocumentSnapshot> documents =
                              snapshot.data!.docs.reversed.toList();
                          return ListView.builder(
                              itemCount: documents.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                var data = documents[index].data()
                                    as Map<String, dynamic>;
                                return ChatMessage(
                                  data: data,
                                  mine: _currentUser?.uid == data['uuid'],
                                );
                              });
                      }
                    },
                  )
                : Container(
                    alignment: Alignment.center,
                    child: Text(
                      "Realize o login",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextCompose(
            sendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }
}
