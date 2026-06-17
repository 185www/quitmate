import 'package:flutter/material.dart';

class AssessmentScreen extends StatelessWidget {
  const AssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('自我评估')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(title: const Text('AUDIT-C 酒精使用评估'), trailing: const Icon(Icons.chevron_right), onTap: () {})),
          Card(child: ListTile(title: const Text('FTND 尼古丁依赖评估'), trailing: const Icon(Icons.chevron_right), onTap: () {})),
        ],
      ),
    );
  }
}
