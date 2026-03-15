import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class AppProvider extends ChangeNotifier {
  final model = GenerativeModel(
    model: "geminimodel",
    apiKey: "APIKEY",
  );

  List<Map<String, dynamic>> messages = [];
  bool isSending = false;

  AppProvider() {
    loadPreviousChats();
  }

  Future<void> loadPreviousChats() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("chats")
          .where("userId", isEqualTo: uid)
          .orderBy("timestamp")
          .get();

      messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "sender": data["sender"],
          "message": data["message"],
          "time": DateFormat(
            'hh:mm a',
          ).format((data["timestamp"] as Timestamp).toDate()),
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      print("Error loading chats: $e");
    }
  }

  Future<void> sendMessage(String message) async {
  if (isSending) return;
  isSending = true;
  notifyListeners();

  final uid = FirebaseAuth.instance.currentUser!.uid;
  final now = DateTime.now();
  final formattedTime = DateFormat('hh:mm a').format(now);

  messages.add({"sender": "user", "message": message, "time": formattedTime});
  notifyListeners();

  await FirebaseFirestore.instance.collection("chats").add({
    "userId": uid,
    "sender": "user",
    "message": message,
    "timestamp": now,
  });

  try {
    final response = await model.generateContent([Content.text(message)]);
    String aiMessage = response.text ?? "No Response";
    final aiTime = DateFormat('hh:mm a').format(DateTime.now());

    messages.add({"sender": "ai", "message": aiMessage, "time": aiTime});
    notifyListeners();

    await FirebaseFirestore.instance.collection("chats").add({
      "userId": uid,
      "sender": "ai",
      "message": aiMessage,
      "timestamp": DateTime.now(),
    });
  } catch (e) {
     String aiErrorMessage = e.toString();
    final errorTime = DateFormat('hh:mm a').format(DateTime.now());

    messages.add({
      "sender": "ai",
      "message": aiErrorMessage,
      "time": errorTime,
    });
    notifyListeners();
    print("Error sending AI message: $e");
  }

  isSending = false;
  notifyListeners();
}

  Future<void> clearChat() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("chats")
          .where("userId", isEqualTo: uid)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      messages.clear();
      notifyListeners();
    } catch (e) {
      print("Error clearing chat: $e");
    }
  }
}
