//设置页
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('后端地址'),
            subtitle: Text(ApiConstants.baseUrl),
            trailing: const Icon(Icons.edit),
            onTap: () {
              // 未来可以添加修改API地址的功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('功能开发中')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'AI阅读助手',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 AI Reader',
              );
            },
          ),
        ],
      ),
    );
  }
}