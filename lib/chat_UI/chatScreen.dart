import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gemini_ai/chatProvider/chatProvider.dart';
import 'package:gemini_ai/chat_UI/loadingAnimation.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatModel = context.watch<ChatModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: Text(
          'Gemini Chat',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: isDark ? Colors.black : Colors.white,),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: isDark ? Colors.black : Colors.white,),
            onPressed: () => _showDeleteDialog(context),
          )
        ],
      ),
      body: Column(
        children: [

          /// Chat List

          Expanded(
            child: chatModel.messageList.isEmpty && !chatModel.isLoading
                ? Center(
              child: Text(
                'Start a conversation 👋',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
                :  ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount:
                  chatModel.messageList.length + (chatModel.isLoading ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (chatModel.isLoading &&
                    index == chatModel.messageList.length) {
                  return const TypingBubble();
                }
                final msg = chatModel.messageList[index];
                final isUser = msg.userType == 'user';

                return GestureDetector(
                  onLongPress: () => _showMessageOptions(
                    context,
                    msg.message,
                    index,
                    isUser,
                  ),
                  child: Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.80),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,

                        border: Border.all(
                          color: isUser
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
                              : Theme.of(context).dividerColor,
                          width: 1,
                        ),

                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: isUser
                              ? const Radius.circular(20)
                              : const Radius.circular(4),
                          bottomRight: isUser
                              ? const Radius.circular(4)
                              : const Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: MarkdownBody(
                        data: msg.message,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: isUser
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            height: 1.4,
                          ),
                          strong: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// Input Area

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask Gemini...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: chatModel.isLoading
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: chatModel.isLoading
                        ? null
                        : () {
                            if (messageController.text.trim().isEmpty) return;

                            if (chatModel.editingIndex != null) {
                              chatModel
                                  .updateMessage(messageController.text.trim());
                            } else {
                              chatModel
                                  .sendMessage(messageController.text.trim());
                            }
                            messageController.clear();
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Message Options

  void _showMessageOptions(
      BuildContext context, String message, int index, bool isUser) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Wrap(
        children: [
          if (isUser)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                messageController.text = message;
                context.read<ChatModel>().startEditing(index);
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }


  /// Delete Dialog

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Chats'),
        content: const Text(
            'Are you sure you want to delete all messages?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              context.read<ChatModel>().clearChat();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
