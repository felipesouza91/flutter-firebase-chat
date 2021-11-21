import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextCompose extends StatefulWidget {
  const TextCompose({Key? key, required this.sendMessage}) : super(key: key);

  final Function({String? text, XFile? file}) sendMessage;

  @override
  _TextComposeState createState() => _TextComposeState();
}

class _TextComposeState extends State<TextCompose> {
  bool isComposing = false;
  final TextEditingController textController = TextEditingController();

  void _reset() {
    textController.clear();
    setState(() {
      isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
              onPressed: () async {
                final XFile? imgFile =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (imgFile != null) {
                  widget.sendMessage(file: imgFile);
                }
                return;
              },
              icon: Icon(Icons.photo_camera)),
          Expanded(
            child: TextField(
              controller: textController,
              decoration:
                  InputDecoration.collapsed(hintText: "Enviar uma mensagem"),
              onChanged: (String text) {
                setState(() {
                  isComposing = text.isNotEmpty;
                });
              },
              onSubmitted: (String text) {
                widget.sendMessage(text: text);
                _reset();
              },
            ),
          ),
          IconButton(
              onPressed: isComposing
                  ? () {
                      widget.sendMessage(text: textController.text);
                      _reset();
                    }
                  : null,
              icon: Icon(Icons.send))
        ],
      ),
    );
  }
}
