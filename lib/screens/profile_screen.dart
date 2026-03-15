import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  Map<String, dynamic>? userData;
  bool isLoading = true;
@override
void dispose() {
  nameController.dispose();
  super.dispose();
}
  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection("user").doc(uid).get();

      if (doc.exists) {
        userData = doc.data() as Map<String, dynamic>;
        nameController.text = userData!["name"];
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading user: $e");
    }
  }

  Future<void> updateName() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection("user")
          .doc(uid)
          .update({"name": nameController.text});

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Name updated")));
      loadUser();
    } catch (e) {
      print("Error updating name: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Profile")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Email:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(userData!["email"] ?? ""),
            const SizedBox(height: 20),

            const Text("Name:", style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: updateName,
              child: const Text("Update Name"),
            ),
            const SizedBox(height: 20),

            const Text("Account Created:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(userData!["createdAt"] != null
                ? DateFormat("dd MMM yyyy, hh:mm a")
                    .format(userData!["createdAt"].toDate())
                : ""),
          ],
        ),
      ),
    );
  }
}