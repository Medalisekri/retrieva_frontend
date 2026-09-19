import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../models/chat_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final conversationsAsync = ref.watch(conversationNotifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Messages',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),

      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Not logged in'));
          }

          final myUserId = profile.userId;

          return conversationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (conversations) {
              if (conversations.isEmpty) {
                return _buildEmptyState();
              }

              final sortedConversations = List<Conversation>.from(conversations);
              sortedConversations.sort((a, b) {
                if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
                if (a.lastMessageTime == null) return 1;
                if (b.lastMessageTime == null) return -1;
                return b.lastMessageTime!.compareTo(a.lastMessageTime!);
              });

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sortedConversations.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1, color: AppColors.border, indent: 76, endIndent: 16),
                itemBuilder: (_, i) {
                  final conv = sortedConversations[i];
                  final otherName = conv.getOtherName(myUserId);
                  final otherId = conv.getOtherId(myUserId);

                  return _ChatTile(
                    conversation: conv,
                    otherName: otherName,
                    otherId: otherId,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 52, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 14),
          const Text('No conversations yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Start by messaging someone on a listing',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Conversation conversation;
  final String otherName;
  final int otherId;

  const _ChatTile({
    required this.conversation,
    required this.otherName,
    required this.otherId,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final initials = otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () => context.push(AppRoutes.message, extra: conversation),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initials, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        otherName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_formatTime(conversation.lastMessageTime), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 3),
                if (conversation.itemName.isNotEmpty)
                  Text('Re: ${conversation.itemName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  conversation.lastMessage ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: (conversation.lastMessage?.isEmpty ?? true) ? AppColors.textSecondary.withOpacity(0.5) : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.border, size: 20),
        ]),
      ),
    );
  }
}