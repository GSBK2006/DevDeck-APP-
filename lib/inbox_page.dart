import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'data.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  bool _isLoading = true;
  List<InboxMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final email = user?.email?.split('@')[0] ?? 'Anon';

      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('to_user', email)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;

      setState(() {
        _messages = data
            .map((json) => InboxMessage(
                  id: json['id'].toString(),
                  fromUser: json['from_user'] ?? 'Unknown',
                  projectTitle: json['project_title'] ?? 'Unknown Project',
                  projectId: json['project_id'].toString(),
                  status: json['status'] ?? 'pending',
                  type: json['type'] ?? 'info',
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Inbox Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(InboxMessage msg) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'status': 'accepted'}).eq('id', msg.id);

      final projectRes = await Supabase.instance.client
          .from('projects')
          .select('permitted_users')
          .eq('id', msg.projectId)
          .single();

      List<dynamic> currentPerms = projectRes['permitted_users'] ?? [];

      if (!currentPerms.contains(msg.fromUser)) {
        currentPerms.add(msg.fromUser);

        await Supabase.instance.client
            .from('projects')
            .update({'permitted_users': currentPerms}).eq('id', msg.projectId);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.green,
            content: Text("ACCESS GRANTED TO ${msg.fromUser}")));
      }

      final user = Supabase.instance.client.auth.currentUser;
      final myEmail = user?.email?.split('@')[0] ?? 'Anon';

      await Supabase.instance.client.from('notifications').insert({
        'type': 'access_granted',
        'from_user': myEmail,
        'to_user': msg.fromUser,
        'project_id': int.parse(msg.projectId),
        'project_title': msg.projectTitle,
        'status': 'unread'
      });

      _fetchInbox();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("INBOX", style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        iconTheme:
            IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      body: _isLoading
          // Fixed: Removed const
          ? Center(child: CircularProgressIndicator(color: AppTheme.neonBlue))
          : _messages.isEmpty
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.tray(), size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text("NO NEW MESSAGES",
                        style: AppTheme.fontCode.copyWith(color: Colors.grey)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];

                    if (msg.type == 'access_granted') {
                      return _buildGrantedMessage(msg, isDark);
                    }
                    return _buildRequestMessage(msg, isDark);
                  },
                ),
    );
  }

  Widget _buildRequestMessage(InboxMessage msg, bool isDark) {
    final isPending = msg.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 5)
                ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.userCircle(),
                      color: AppTheme.neonBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(msg.fromUser,
                      style:
                          AppTheme.fontCode.copyWith(color: AppTheme.neonBlue)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(msg.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: isPending ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: "Requested access to: "),
                  TextSpan(
                      text: msg.projectTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
          ),
          const SizedBox(height: 15),
          if (isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonBlue,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _acceptRequest(msg),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text("GRANT ACCESS")),
            )
        ],
      ),
    );
  }

  Widget _buildGrantedMessage(InboxMessage msg, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ACCESS GRANTED",
                    style: AppTheme.fontCode.copyWith(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("You can now view details for ${msg.projectTitle}",
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          )
        ],
      ),
    );
  }
}
