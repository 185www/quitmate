import 'package:flutter/material.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('认知教育')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(child: ListTile(title: Text('成瘾的神经科学'), subtitle: Text('了解成瘾如何改变大脑'))),
          Card(child: ListTile(title: Text('戒断的益处'), subtitle: Text('身体和心理的积极变化'))),
        ],
      ),
    );
  }
}
