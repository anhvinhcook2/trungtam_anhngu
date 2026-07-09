import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProgressionScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentProgressionScreen({super.key, required this.studentId, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lộ trình học: $studentName")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .where('studentIds', arrayContains: studentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var classes = snapshot.data!.docs;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("Tổng quan lộ trình", style: Theme.of(context).textTheme.headlineSmall),
              ...classes.map((c) {
                var data = c.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(data['name']),
                    subtitle: Text("Cấp độ: ${data['level']} | Môn: ${data['subject']}"),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
