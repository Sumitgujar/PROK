import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/notification_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});
  @override State<StudentNotificationsScreen> createState() => _N();
}
class _N extends State<StudentNotificationsScreen> {
  @override void initState() { super.initState(); Future.microtask(() => context.read<NotificationProvider>().fetchNotifications()); }
  @override Widget build(BuildContext context) {
    final p = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'),
        actions: [if (p.notifications.any((n) => !n.isRead)) TextButton(onPressed: () => context.read<NotificationProvider>().markAllRead(), child: const Text('Mark all read'))]),
      body: p.state == ProviderState.loading ? const LoadingWidget()
        : p.state == ProviderState.error ? ErrorStateWidget(error: p.error ?? 'Error', onRetry: () => context.read<NotificationProvider>().fetchNotifications())
        : p.notifications.isEmpty ? const EmptyStateWidget(title: 'All caught up', subtitle: 'No new notifications', icon: Icons.notifications_outlined)
        : ListView.separated(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: p.notifications.length, separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) { final n = p.notifications[i]; return ListTile(
            tileColor: n.isRead ? null : ProkColors.primarySurface,
            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: n.isRead ? ProkColors.neutral100 : ProkColors.primarySurface, shape: BoxShape.circle),
              child: Icon(Icons.notifications_rounded, color: n.isRead ? ProkColors.neutral400 : ProkColors.primary, size: 18)),
            title: Text(n.title, style: TextStyle(fontSize: 14, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700, color: ProkColors.neutral900)),
            subtitle: n.body != null ? Text(n.body!, style: const TextStyle(fontSize: 13, color: ProkColors.neutral600)) : null,
            trailing: !n.isRead ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: ProkColors.primary, shape: BoxShape.circle)) : null,
            onTap: () => context.read<NotificationProvider>().markRead(n.id),
          ); }));
  }
}
