import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:retrieva/core/services/cloudinary_service.dart';
import 'package:retrieva/providers/chat_provider.dart';
import '../core/theme/apptheme.dart';
import '../models/chat_model.dart';


class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {

  final _auth        = FirebaseAuth.instance;
  final _msgCtrl     = TextEditingController();
  final _scrollCtrl  = ScrollController();

  late String _chatId;
  late int _otherUserId;
  late int _convId;
  late String _otherName;
  late String _itemTitle;

  Message? _editingMsg;
  bool _isBlocked    = false;
  bool _sending      = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      setState(() {
        _chatId      = args['chatId'];
        _otherUserId = args['otherUserId'];
        _otherName   = args['otherName'];
        _itemTitle   = args['itemTitle'];
      });
      _loadConversation();
    });
    Future.microtask(() async {await ref.read(messageNotifier.notifier).getMessages();});
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _myUid => _auth.currentUser!.uid;

  Future<void> _loadConversation() async {
    final conversation = await ref.read(chatRepositoryProvider)
        .getConversation(_convId);

    setState(() {
      _isBlocked = conversation.isBlocked;

    });
  }

  // ── Send text message ─────────────────────────────────
  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();
try{
  await _addMessage(conversationId: _convId, text: _msgCtrl.text.trim());
}finally{
  setState(() {
    _sending = false;
  });
}


  }

  // ── Send image ────────────────────────────────────────
  Future<void> _sendImage() async {
    final  cloudinary = CloudinaryService();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    setState(() => _sending = true);
    try {
      final bytes = await picked.readAsBytes();
      final url   = await cloudinary.uploadBytes(  bytes,
        folder: 'retrieva/items',);
      if (url != null) await _addMessage(imgUrl: url ,  conversationId: _convId);
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _addMessage({required int conversationId , String text = '', String imgUrl = ''}) async {
    await ref.read(messageNotifier.notifier).sendMessage(conversationId: conversationId, text: text, imgUrl: imgUrl);

    _scrollToBottom();
  }

  // ── Delete message ────────────────────────────────────
  Future<void> _deleteMessage(Message message) async {
await ref.read(messageNotifier.notifier).deleteMessage(message);
  }
  // ── Block / Unblock ───────────────────────────────────
  Future<void> _toggleBlock( ) async {
    await ref.read(conversationNotifier.notifier).blockOtherUser( conversationId: _convId );
    setState(() {
      _isBlocked = true;

    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgState = ref.watch(messageNotifier);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_otherName,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text(_itemTitle,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6))),
          ],
        ),
        actions: [
          PopupMenuButton<dynamic>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              PopupMenuItem<dynamic>(
                onTap: _toggleBlock,
                child: Row(children: [
                  Icon(
                    _isBlocked
                        ? Icons.lock_open_outlined
                        : Icons.block_outlined,
                    size: 18,
                    color: _isBlocked
                        ? AppColors.teal
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isBlocked ? 'Unblock User' : 'Block User',
                    style: TextStyle(
                        fontSize: 13,
                        color: _isBlocked
                            ? AppColors.teal
                            : Colors.redAccent),
                  ),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages list ─────────────────────────────
          Expanded(
            child: msgState.when(
              loading: () =>
              const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.teal)),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Something went wrong : $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (messages) {
                final msg = messages.toList();
                if (msg.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: AppColors.textSecondary
                                .withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('No messages yet',
                            style: TextStyle(
                                color: AppColors.textSecondary
                                    .withOpacity(0.6),
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Say hello!',
                            style: TextStyle(
                                color: AppColors.teal,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
                );
              },
            ),
          ),

          // ── Blocked banner ────────────────────────────
          if (_isBlocked)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.redAccent.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block_outlined,
                      size: 16, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  const Text('You blocked this user.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.redAccent)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleBlock,
                    child: const Text('Unblock',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          // ── Edit banner ───────────────────────────────
          if (_editingMsg != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: AppColors.teal.withOpacity(0.08),
              child: Row(children: [
                const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Editing: ${_editingMsg!.text}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.teal),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _editingMsg = null);
                    _msgCtrl.clear();
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.teal),
                ),
              ]),
            ),

          // ── Input bar ─────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(children: [
                // Image button
                GestureDetector(
                  onTap: _isBlocked ? null : _sendImage,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _isBlocked
                          ? AppColors.border
                          : AppColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.image_outlined,
                        color: _isBlocked
                            ? AppColors.textSecondary
                            : AppColors.teal,
                        size: 20),
                  ),
                ),
                const SizedBox(width: 8),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    enabled: !_isBlocked,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: _isBlocked
                          ? 'You blocked this user'
                          : 'Type a message...',
                      hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 14),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: _isBlocked ? null : _sendText,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _isBlocked
                          ? AppColors.border
                          : AppColors.teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _sending
                        ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                        : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Message bubble ────────────────────────────────────
  Widget _buildMessageBubble(Message msg) {
    final isMe = msg.isMine;

    if (msg.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Message deleted',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic)),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: isMe ? () => _showMessageOptions(msg) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: msg.hasImage
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.teal : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: msg.hasImage
                    ? ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  child: Image.network(msg.imageUrl!,
                      width: 200,
                      fit: BoxFit.cover),
                )
                    : Text(msg.text,
                    style: TextStyle(
                        fontSize: 14,
                        color: isMe
                            ? Colors.white
                            : AppColors.textPrimary)),
              ),


            ],
          ),
        ),
      ),
    );
  }

  // ── Message options (long press) ──────────────────────
  void _showMessageOptions(Message msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),



            // Delete
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              title: const Text('Delete Message',
                  style: TextStyle(
                      fontSize: 14, color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(msg);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }


}