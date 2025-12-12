import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 监听 AuthProvider，如果未登录则显示登录提示（这里简化为按钮跳转）
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('学习中心')),
      body: SafeArea(
        child: !auth.isLoggedIn
            ? _buildLoginPrompt(context)
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- 菜单区域 ---
                  _buildMenuCard(
                    context,
                    title: '预约座位',
                    description: '预约空闲自习座位',
                    icon: Icons.event_seat,
                    onTap: () => context.push('/time_select'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    context,
                    title: '我的预约',
                    description: '查看过往预约记录',
                    icon: Icons.history,
                    onTap: () => context.push('/history'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    context,
                    title: '座位预约情况',
                    description: '查看座位实时预约状态',
                    icon: Icons.event_available,
                    onTap: () => context.push('/seat_availability'),
                  ),

                  const SizedBox(height: 32),

                  // --- 提示信息区域 ---
                  _buildInfoSection('预约流程', [
                    '打开"预约座位" -> 选择时间段 -> 查找可用座位 -> 确认预约',
                    '同时可在"座位状态"页面中点击"已占用"的座位，查看该座位当天的可用时段',
                  ]),
                  _buildInfoSection('签到流程', ['打开"我的预约" -> 扫码签到 -> 签到成功']),
                ],
              ),
      ),
    );
  }

  // 构建未登录提示
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('登录统一身份认证平台'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  // 构建菜单卡片 (对应 LabelEntry)
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0, // 扁平风格
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          description,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // 构建信息段落
  Widget _buildInfoSection(String title, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                line,
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
