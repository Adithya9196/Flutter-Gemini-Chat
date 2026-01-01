import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gemini_ai/ChatModel/chatModel.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';

class ChatModel extends ChangeNotifier {

  bool isLoading = false;
  int? editingIndex;

  late ChatSession chatSession;

  final model = GenerativeModel(
      model: "gemini-2.5-flash",
      apiKey: dotenv.env['GEMINI_API_KEY']!,
  );

  final Box<ChatMessage> chatBox = Hive.box<ChatMessage>('chatBox');

  List<ChatMessage> messageList = [];

  ChatModel(){
    loadChats();
    _initChatSession();
  }

  void _initChatSession() {
    chatSession = model.startChat(
      history: _buildChatHistory(),
    );
  }

  List<Content> _buildChatHistory({int limit = 10}) {
    final recentMessages =
    messageList.length > limit
        ? messageList.sublist(messageList.length - limit)
        : messageList;

    return recentMessages.map((msg) {
      if (msg.userType == 'user') {
        return Content.text(msg.message);
      } else {
        return Content.model([
          TextPart(msg.message),
        ]);
      }
    }).toList();
  }

  Future<void> sendMessage(String message) async{

    final userMessage = ChatMessage(
      message: message,
      userType: 'user',
      timestamp: DateTime.now(),
    );

    messageList.add(userMessage);
    isLoading = true;
    notifyListeners();
    saveChatMessage(userMessage);

    try{
      final response = await chatSession.sendMessage(
        Content.text(message)
      );

      final geminiMessage = ChatMessage(
        message: response.text ?? 'No response',
        userType: 'gemini',
        timestamp: DateTime.now(),
      );

      messageList.add(geminiMessage);
      chatBox.add(geminiMessage);
      saveChatMessage(geminiMessage);

    }catch(e){
      final errorMessage = ChatMessage(
        message: 'Error: $e',
        userType: 'gemini',
        timestamp: DateTime.now(),
      );
      messageList.add(errorMessage);
      chatBox.add(errorMessage);
    }
    isLoading = false;
    notifyListeners();
    //saveChats();
  }


  void saveChatMessage(ChatMessage message) {
    chatBox.add(message);
  }


  void loadChats() {
    messageList = chatBox.values.toList();
    notifyListeners();
  }

  void clearChat(){
    chatBox.clear();
    messageList.clear();
    notifyListeners();
  }

  void startEditing(int index){
    editingIndex = index;
  }

  Future<void> updateMessage(String newText) async{
    if(editingIndex == null) return;

    final index = editingIndex!;
    final oldUserMsg = messageList[index];

    final updatedUserMsg = ChatMessage(
      message: newText,
      userType: 'user',
      timestamp: DateTime.now(),
    );

    // update user message
    chatBox.putAt(index, updatedUserMsg);
    messageList[index] = updatedUserMsg;

    // remove old gemini reply if exists
    if (index + 1 < messageList.length &&
        messageList[index + 1].userType == 'gemini') {
      chatBox.deleteAt(index + 1);
      messageList.removeAt(index + 1);
    }


    isLoading = true;
    editingIndex = null;
    notifyListeners();
    //saveChats();

    try{
      final response = await model.generateContent([
        Content.text(newText)
      ]);

      final geminiMsg = ChatMessage(
        message: response.text ?? 'No response',
        userType: 'gemini',
        timestamp: DateTime.now(),
      );

      chatBox.add(geminiMsg);
      messageList.add(geminiMsg);

    }catch(e){
      final errorMsg = ChatMessage(
        message: 'Error: $e',
        userType: 'gemini',
        timestamp: DateTime.now(),
      );
      chatBox.add(errorMsg);
      messageList.add(errorMsg);
    }
    isLoading = false;
    notifyListeners();
    //saveChats();
  }

}
