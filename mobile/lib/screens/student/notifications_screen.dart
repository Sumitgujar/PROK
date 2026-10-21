import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/notification_provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/models/notification_model.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});
  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  String? _actionError;
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NotificationProvider>().loadNotifications());
  }

  Future<void> _markRead(NotificationModel notification) async {
    if (notification.isRead) return;
    try {
      await context.read<NotificationProvider>().markRead(notification.id);
    } catch (error) {
      if (mounted) setState(() => _actionError = error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _markAllRead() async {
    setState(() { _markingAll = true; _actionError = null; });
    try {
      await context.read<NotificationProvider>().markAllRead();
    } catch (error) {
      if (mounted) setState(() => _actionError = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationProvider>();
    final unread = p.notifications.where((item) => !item.isRead).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markingAll ? null : _markAllRead,
              child: Text(_markingAll ? 'Saving…' : 'Mark all read'),
            ),
          IconButton(
            tooltip: 'Refresh notifications',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<NotificationProvider>().loadNotifications(),
          ),
        ],
      ),
      body: p.state == ProviderState.loading && p.notifications.isEmpty
        ? const LoadingWidget(message: 'Loading notifications…')
        : p.state == ProviderState.error && p.notifications.isEmpty
          ? ErrorStateWidget(
              error: p.error ?? 'Notifications could not be loaded.',
              onRetry: () => context.read<NotificationProvider>().loadNotifications(),
            )
          : Column(children: [
              if (unread > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: ProkColors.primarySurface, borderRadius: ProkRadius.md),
                  child: Text(
                    unread.toString() + (unread == 1 ? ' unread notification' : ' unread notifications'),
                    style: const TextStyle(fontSize: 13, color: ProkColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              if (_actionError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text(_actionError!, style: const TextStyle(fontSize: 12, color: ProkColors.error)),
                ),
              Expanded(
                child: p.notifications.isEmpty
                  ? const EmptyStateWidget(title: 'All caught up', subtitle: 'Your college updates will appear here.', icon: Icons.notifications_outlined)
                  : RefreshIndicator(
                      color: ProkColors.primary,
                      onRefresh: () => context.read<NotificationProvider>().loadNotifications(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: p.notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final note = p.notifications[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            tileColor: note.isRead ? null : ProkColors.primarySurface.withOpacity(0.5),
                            leading: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: note.isRead ? ProkColors.neutral100 : ProkColors.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_iconFor(note.ntype),
                                color: note.isRead ? ProkColors.neutral400 : ProkColors.primary, size: 19),
                            ),
                            title: Text(note.title,
                              style: TextStyle(fontSize: 14, fontWeight: note.isRead ? FontWeight.w500 : FontWeight.w800, color: ProkColors.neutral900)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(note.message, style: const TextStyle(fontSize: 12, height: 1.4, color: ProkColors.neutral600)),
                                if (note.createdAt.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(note.createdAt.replaceFirst('T', ' ').split('.').first,
                                      style: const TextStyle(fontSize: 10, color: ProkColors.neutral400)),
                                ],
                              ],
                            ),
                            trailing: note.isRead
                              ? const Icon(Icons.check_circle_outline_rounded, color: ProkColors.neutral200, size: 18)
                              : Container(width: 8, height: 8, decoration: const BoxDecoration(color: ProkColors.primary, shape: BoxShape.circle)),
                            onTap: () => _markRead(note),
                          );
                        },
                      ),
                    ),
              ),
            ]),
    );
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'attendance': return Icons.fact_check_outlined;
      case 'document': return Icons.description_outlined;
      case 'scholarship': return Icons.school_outlined;
      case 'course': return Icons.menu_book_outlined;
      default: return Icons.notifications_outlined;
    }
  }
}
