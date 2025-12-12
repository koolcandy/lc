import 'package:flutter/material.dart';
import '../data/models/appointment.dart';
import '../data/services/api_service.dart';

class AppointmentCard extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback onRefresh;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onRefresh,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  bool _isLoading = false;

  // 获取状态颜色
  Color _getStatusColor() {
    final text = widget.appointment.statusText;
    switch (text) {
      case '未开始':
        return Colors.blue;
      case '待签到':
        return Colors.orange;
      case '已签到':
      case '已完成':
        return Colors.green;
      case '未签到': // 对应 RN 的 red-600
        return Colors.red;
      case '已取消':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // 取消预约
  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消预约'),
        content: const Text('确定要取消预约吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().cancelAppointment(widget.appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('取消成功')));
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('取消失败: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 签退
  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('签退'),
        content: const Text('确定要结束学习并签退吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('签退')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().signOut(widget.appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('签退成功')));
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('签退失败: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 签到
  void _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ApiService().signIn(widget.appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('签到成功')));
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('签到失败: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = widget.appointment.statusText;

    // 根据逻辑规范化座位名称 (对应 RN 的 normalizeSpaceName)
    String displaySpaceName = widget.appointment.spaceName;
    if (displaySpaceName == '796-1') displaySpaceName = '797';
    if (displaySpaceName == '799-1') displaySpaceName = '800';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.appointment.floor}层 $displaySpaceName",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "# ${widget.appointment.id}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem("日期", widget.appointment.date),
                _buildInfoItem("时间", "${widget.appointment.beginTime} - ${widget.appointment.endTime}"),
              ],
            ),
          ),
          
          // Action Buttons
          if (statusText == '未开始' || statusText == '待签到' || statusText == '已签到')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: _buildActionButton(statusText),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActionButton(String statusText) {
    if (_isLoading) {
      return const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (statusText == '未开始') {
      return OutlinedButton(
        onPressed: _handleCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        child: const Text('取消预约'),
      );
    } else if (statusText == '待签到') {
      return FilledButton(
        onPressed: _handleSignIn,
        child: const Text('签到'),
      );
    } else if (statusText == '已签到') {
      return FilledButton(
        onPressed: _handleSignOut,
        style: FilledButton.styleFrom(backgroundColor: Colors.blue),
        child: const Text('签退'),
      );
    }
    return const SizedBox.shrink();
  }
}