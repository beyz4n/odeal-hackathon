import 'dart:convert';
import 'package:azure_chat/src/api_keys.dart'; // make sure you create a local version of this file with your specific keys!
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

enum MessageType {
  user,
  assistant,
  system
}

class ChatMessage {
  String content;
  MessageType messageType;

  // will automatically be called by jsonEncode()
  Map<String, String> toJson() {
    return {'role': messageType.name, 'content': content};
  }

  ChatMessage({required this.content, required this.messageType});
}

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  var aa = "";
  final _textInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  final List<ChatMessage> _chatMessages = [
    ChatMessage(content: 'Merhaba ben Ödeal yardımcı botuyum. Nasıl yardımcı olabilirim ?', messageType: MessageType.system),
  ];

  @override
  void dispose() {
    // Clean up the controllers
    _textInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    // scroll to the max extent after frame is done rendering (or else maxScrollExtent might not be updated yet)
    SchedulerBinding.instance.addPostFrameCallback((_) => _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200), curve: Curves.fastOutSlowIn));
  }

  void _onSendPress() {
    // ignore if no text
    if (_textInputController.text.isEmpty) return;

    // add message to list and query assistant response
    setState(() {
      _chatMessages.add(ChatMessage(content: _textInputController.text, messageType: MessageType.user));
      _isLoading = true;
      aa = _textInputController.text;
      print(aa);
    });
    _textInputController.clear();
    uploadTextToServer(aa);
    //_queryAssistantResponse();

    // unfocus primary node -> will dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();
    _scrollToEnd();
  }

  void _queryAssistantResponse() async {
  // prepare and send request
  final response = await http.post(
    Uri.parse(AZURE_OPENAI_ENDPOINT),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'api-key': AZURE_OPENAI_KEY,
    },
    body: jsonEncode({'messages': _chatMessages}),
  );

  // make sure response is successful
  if (response.statusCode != 200) {
    print('Failed to fetch from Azure OpenAI. Check your Azure OpenAI endpoint and key.');
    return;
  }

  // parse body to extract message
  final body = jsonDecode(response.body);
  String? message;
  try {
    message = body['choices'][0]['message']['content'];
  } catch (e) {
    print('Failed to parse response body with error ${e.toString()}');
    return;
  }

  // validate message and store it in the aa variable
  if (message == null || message.isEmpty) {
    print('Failed to parse response body.');
    return;
  }

  setState(() {
      //aa = message!;
      //print(aa);
      _chatMessages.add(ChatMessage(content: message!, messageType: MessageType.assistant));
      _isLoading = false;
    });
  _scrollToEnd();
  // Send the message to the server
  uploadTextToServer(aa);
}


  //fastapi
  Future<void> uploadTextToServer(String text) async {
  String? message;
  final url = 'http://10.0.2.2:8000/uploadstring/';

  try {
    final response = await http.post(
      Uri.parse(url),
      body: {'content': text},
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(Utf8Decoder().convert(response.bodyBytes));
      message = responseBody; // Assign the response to the 'message' variable
      print('Response from server: $responseBody');
      // You can parse the response JSON here and handle it accordingly.
    } else {
      print('Failed to upload text. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }

  setState(() {
    _chatMessages.add(ChatMessage(content: message ?? 'No response', messageType: MessageType.assistant));
    _isLoading = false;
  });
  _scrollToEnd();
}



  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final screenHeight = MediaQuery.of(context).size.height;
  return Container(
    padding: const EdgeInsets.only(bottom: 10, left: 8.0, right: 8.0),
    color: theme.colorScheme.background,
    child: Column(
      children: [
        Expanded(
  child: ListView.builder(
  controller: _scrollController,
  padding: const EdgeInsets.all(0),
  itemCount: _chatMessages.length,
  itemBuilder: (BuildContext context, int index) {
    final isClientMessage = _chatMessages[index].messageType == MessageType.user;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: Row(
        mainAxisAlignment: isClientMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isClientMessage)
            Container(
              
              padding: const EdgeInsets.only(right: 8.0),
              child: ClipOval(
                child: Image.asset(
                  'assets/odeal_icon.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: isClientMessage ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.all(8),
              child: MarkdownBody(
                styleSheet: MarkdownStyleSheet.fromTheme(
                  theme.copyWith(cardTheme: const CardTheme(color: Colors.white)),
                ),
                data: _chatMessages[index].content,
              ),
            ),
          ),
          if (isClientMessage)
            Container(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.blue,
                child: Text('You', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      )
    );
  },
),

),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey, // Outline color
                      width: 1.0, // Outline width
                    ),
                  ),
                  child: TextField(
                    // scroll to end after the keyboard is visible
                    onTap: () => Future.delayed(const Duration(milliseconds: 500), _scrollToEnd),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10),
                      border: InputBorder.none,
                      hintText: 'Send a message',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    controller: _textInputController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 6,
                    minLines: 1,
                  ),
                ),
              ),
              const SizedBox(
                // used to add a little spacing between the elements
                width: 8,
              ),
              SizedBox(
                // using a SizedBox as parent so that ElevatedButton and Loading are the same size
                width: 45,
                height: 45,
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primaryContainer,
                        ),
                      )
                    : ElevatedButton(
                      //bunu değiştirdim _onSendPress yerine
                        onPressed: _onSendPress,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(0),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
              ),
              
            ],
          ),
        )
      ],
    ),
  );
}

  
}
