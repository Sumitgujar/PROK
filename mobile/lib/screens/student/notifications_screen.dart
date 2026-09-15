import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/providers/notification_provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});
  @override State<StudentNotificationsScreen> createState() => _State();
}

class _State extends State<StudentNotificationsScreen> {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<NotificationProvider>().loadNotifications());
  }

  IconData _icon(String ntype) {
    switch (ntype) {
      case 'scholarship': return Icons.monetization_on;
      case 'attendance': return Icons.fact_check;
      case 'document': return Icons.folder;
      case 'course': return Icons.school;
      default: return Icons.info_outline;
    }
  }

  @override Widget build(BuildContext context) {
    final prov = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (prov.unreadCount > 0)
            TextButton(
              onPressed: () => context.read<NotificationProvider>().markAllRead(),
              child: const Text('Mark all read', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationProvider>().loadNotifications(),
        child: Builder(builder: (_) {
          if (prov.isLoading) return const LoadingWidget();
          if (prov.state == ProviderState.error)
            return ErrorStateWidget(
                error: prov.error!,
                onRetry: () => context.read<NotificationProvider>().loadNotifications());
          if (prov.notifications.isEmpty)
            return const EmptyStateWidget(
                title: 'No notifications', icon: Icons.notifications_off_outlined);
          return ListView.separated(
            itemCount: prov.notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final n = prov.notifications[i];
              return ListTile(
                tileColor: n.isRead ? null : const Color(0xFFEEF2FF),
                leading: CircleAvatar(
                  backgroundColor: n.isRead ? Colors.grey[200] : const Color(0xFF1E3A8A),
                  child: Icon(_icon(n.ntype),
                      color: n.isRead ? Colors.grey : Colors.white, size: 18)),
                title: Text(n.title,
                    style: TextStyle(
                        fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(
                      n.createdAt.length >= 10 ? n.createdAt.substring(0, 10) : n.createdAt,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
                isThreeLine: true,
                onTap: n.isRead ? null : () => context.read<NotificationProvider>().markRead(n.id),
                trailing: n.isRead
                    ? null
                    : Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFF1E3A8A), shape: BoxShape.circle)),
              );
            },
          );
        }),
      ),
    );
  }
}
