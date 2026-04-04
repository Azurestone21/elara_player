
import 'package:elara_player/src/components/components.dart';
import 'package:flutter/material.dart';

/// 页面不存在页面
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: WindowsAppBar(
        title: '',
      ),
      body: Center(
        child: Text('页面不存在'),
      ),
    );
  }
}