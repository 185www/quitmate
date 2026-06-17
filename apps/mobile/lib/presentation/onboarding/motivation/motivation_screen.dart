import 'package:flutter/material.dart';

class MotivationScreen extends StatelessWidget {
  const MotivationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('动机提升')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(child: ListTile(title: Text('个人动机清单'), subtitle: Text('列出你戒断的理由'))),
          Card(child: ListTile(title: Text('成功故事'), subtitle: Text('看看其他人如何成功戒断'))),
        ],
      ),
    );
  }
}
