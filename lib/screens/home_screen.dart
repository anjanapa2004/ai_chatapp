import 'package:ai_chat_app/appprovider.dart';
import 'package:ai_chat_app/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chat App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              context.read<AppProvider>().clearChat();
            },
          ),
          IconButton(
  icon: const Icon(Icons.person),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  },
),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          ),

        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      final msg = provider.messages[index];
                      bool isUser = msg["sender"] == "user";
                      return Align(
                        alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment:
                              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                msg["message"],
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            Text(
                              msg["time"] ?? "",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: "Hey, something on your mind?",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (messageController.text.isEmpty) return;
                        provider.sendMessage(messageController.text);
                        messageController.clear();
                        _scrollToBottom();
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}