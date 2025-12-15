import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'data.dart';

class ChatPage extends StatefulWidget {
  final String otherUser;
  const ChatPage({super.key, required this.otherUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  String _myUsername = "";
  String? _otherUserAvatar;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _getMyUsername();
    await _getOtherUserProfile();
    _markMessagesAsRead();
  }

  Future<void> _getMyUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() => _myUsername = user.email?.split('@')[0] ?? 'Anon');
      }
    }
  }

  Future<void> _getOtherUserProfile() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('avatar_url')
        .eq('username', widget.otherUser)
        .maybeSingle();

    if (mounted && data != null) {
      setState(() {
        _otherUserAvatar = data['avatar_url'];
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_myUsername.isEmpty) return;
    await Supabase.instance.client
        .from('messages')
        .update({'is_read': true})
        .eq('sender_username', widget.otherUser)
        .eq('receiver_username', _myUsername);
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && imageUrl == null) || _myUsername.isEmpty) return;
    _messageController.clear();
    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_username': _myUsername,
        'receiver_username': widget.otherUser,
        'content': text,
        'resource_url': imageUrl,
        'is_read': false,
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to send: $e")));
    }
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileExt = image.path.split('.').last;
        final fileName =
            'chat_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = '/chat/$fileName';
        await Supabase.instance.client.storage.from('images').uploadBinary(
            filePath, bytes,
            fileOptions: FileOptions(contentType: image.mimeType));
        final url = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(filePath);
        _sendMessage(imageUrl: url);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Upload Error: $e")));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: _otherUserAvatar != null
                  ? NetworkImage(_otherUserAvatar!)
                  : null,
              child: _otherUserAvatar == null
                  ? Text(widget.otherUser[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12))
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("@${widget.otherUser}",
                    style: AppTheme.fontTech.copyWith(fontSize: 16)),
                Text("Online",
                    style: AppTheme.fontCode
                        .copyWith(fontSize: 10, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
        backgroundColor: isDark ? AppTheme.cardBg : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: Supabase.instance.client.from('messages').stream(
                  primaryKey: ['id']).order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.neonBlue));
                }

                final allMessages = snapshot.data as List<dynamic>;
                final conversation = allMessages.where((m) {
                  final s = m['sender_username'];
                  final r = m['receiver_username'];
                  return (s == _myUsername && r == widget.otherUser) ||
                      (s == widget.otherUser && r == _myUsername);
                }).toList();

                if (conversation.isEmpty) {
                  return Center(
                      child: Text(
                          "Start a conversation with @${widget.otherUser}",
                          style:
                              AppTheme.fontCode.copyWith(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: conversation.length,
                  itemBuilder: (context, index) {
                    final msg = conversation[index];
                    final isMe = msg['sender_username'] == _myUsername;
                    final hasImage = msg['resource_url'] != null;

                    String time = "";
                    try {
                      time = DateFormat('h:mm a')
                          .format(DateTime.parse(msg['created_at']).toLocal());
                    } catch (e) {
                      time = "";
                    }

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppTheme.neonBlue
                              : (isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft:
                                isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight:
                                isMe ? Radius.zero : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasImage)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(msg['resource_url'],
                                        height: 150, fit: BoxFit.cover)),
                              ),
                            if (msg['content'] != null &&
                                msg['content'].isNotEmpty)
                              // Updated to use Dynamic Font Size
                              Text(msg['content'],
                                  style: AppTheme.bodyStyle.copyWith(
                                      color: isMe
                                          ? Colors.black
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black),
                                      fontSize: 16 *
                                          AppTheme.fontScaleNotifier.value)),
                            const SizedBox(height: 4),
                            Text(time,
                                style: AppTheme.fontCode.copyWith(
                                    color: isMe ? Colors.black54 : Colors.grey,
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            LinearProgressIndicator(color: AppTheme.neonBlue, minHeight: 2),
          Container(
            padding: const EdgeInsets.all(10),
            color: isDark ? AppTheme.cardBg : Colors.white,
            child: Row(
              children: [
                IconButton(
                    icon: Icon(PhosphorIcons.plus(), color: Colors.grey),
                    onPressed: _pickAndSendImage),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(PhosphorIcons.paperPlaneRight(),
                      color: AppTheme.neonBlue),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
