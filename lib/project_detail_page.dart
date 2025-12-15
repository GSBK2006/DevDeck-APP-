import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'data.dart';
import 'chat_page.dart'; // Import Chat Page

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final _commentController = TextEditingController();
  bool _hasAccess = false;
  bool _requestSent = false;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    final user = Supabase.instance.client.auth.currentUser;
    final myEmail = user?.email?.split('@')[0] ?? 'Anon';

    setState(() {
      _isMe = widget.project.author == myEmail;
      _hasAccess = widget.project.permittedUsers.contains(myEmail) || _isMe;
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Could not launch $url")));
    }
  }

  Future<void> _requestAccess() async {
    setState(() => _requestSent = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final myEmail = user?.email?.split('@')[0] ?? 'Anon';

      await Supabase.instance.client.from('notifications').insert({
        'type': 'access_request',
        'from_user': myEmail,
        'to_user': widget.project.author,
        'project_id': int.parse(widget.project.id),
        'project_title': widget.project.title,
        'status': 'pending'
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppTheme.neonBlue,
            content: Text("REQUEST SENT TO @${widget.project.author}",
                style: AppTheme.fontCode.copyWith(color: Colors.black))));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _requestSent = false);
    }
  }

  void _showComments() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 50,
                          height: 4,
                          color: Colors.grey,
                          margin: const EdgeInsets.only(bottom: 20))),
                  Text("COMMENTS (${widget.project.comments.length})",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.project.comments.length,
                      itemBuilder: (context, index) {
                        final commentData = widget.project.comments[index];
                        String username = "Anonymous";
                        String text = commentData;
                        String time = "";

                        if (commentData.contains("|")) {
                          final parts = commentData.split("|");
                          username = parts[0];
                          final timeStr = parts[1];
                          text = parts.length > 2
                              ? parts.sublist(2).join("|")
                              : "";
                          try {
                            final date = DateTime.parse(timeStr).toLocal();
                            time = DateFormat('MMM d • h:mm a').format(date);
                          } catch (e) {
                            time = "";
                          }
                        } else if (commentData.contains(": ")) {
                          final parts = commentData.split(": ");
                          username = parts[0];
                          text = parts.sublist(1).join(": ");
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                              backgroundColor: Colors.grey[800],
                              radius: 15,
                              child: const Icon(Icons.person,
                                  size: 15, color: Colors.white)),
                          title: Row(
                            children: [
                              Text(username,
                                  style: AppTheme.fontCode.copyWith(
                                      fontSize: 12, color: AppTheme.neonBlue)),
                              const SizedBox(width: 8),
                              Text(time,
                                  style: AppTheme.fontCode.copyWith(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          subtitle: Text(text,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 14)),
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: const InputDecoration(
                              hintText: "Add a comment...",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none),
                        ),
                      ),
                      IconButton(
                        icon: Icon(PhosphorIcons.paperPlaneRight(),
                            color: AppTheme.neonBlue),
                        onPressed: () async {
                          if (_commentController.text.isNotEmpty) {
                            final user =
                                Supabase.instance.client.auth.currentUser;
                            final username =
                                user?.email?.split('@')[0] ?? "Anon";
                            final timestamp = DateTime.now().toIso8601String();
                            final fullComment =
                                "$username|$timestamp|${_commentController.text}";

                            setModalState(() {
                              widget.project.comments.add(fullComment);
                            });
                            _commentController.clear();

                            try {
                              await Supabase.instance.client
                                  .from('projects')
                                  .update({
                                'comments': widget.project.comments
                              }).eq('id', widget.project.id);
                            } catch (e) {
                              debugPrint("Comment Save Error: $e");
                            }
                          }
                        },
                      )
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.project.title,
                  style: AppTheme.fontTech.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: Colors.black, blurRadius: 10)
                      ])),
              background:
                  Image.network(widget.project.imageUrl, fit: BoxFit.cover),
            ),
            actions: [
              // Chat Icon in App Bar for quick access
              if (!_isMe)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20)),
                  child: IconButton(
                    icon: Icon(PhosphorIcons.chatCircleDots(),
                        color: AppTheme.neonBlue),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ChatPage(otherUser: widget.project.author)));
                    },
                  ),
                )
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                          backgroundColor: Colors.grey, radius: 15),
                      const SizedBox(width: 10),
                      Text("@${widget.project.author}",
                          style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.neonBlue.withOpacity(0.1),
                          border: Border.all(color: AppTheme.neonBlue),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("${widget.project.votes} BOOSTS",
                            style: AppTheme.fontCode
                                .copyWith(color: AppTheme.neonBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("ABOUT THE PROJECT",
                      style:
                          theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  const SizedBox(height: 10),
                  Text(widget.project.description,
                      style: theme.textTheme.bodyLarge),

                  const SizedBox(height: 30),
                  Text("TECH STACK",
                      style:
                          theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: widget.project.techStack
                        .map((tech) => Chip(
                              label: Text(tech),
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                              labelStyle: AppTheme.fontCode.copyWith(
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color),
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 30),

                  // --- ACCESS GRANTED AREA ---
                  if (_hasAccess) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green)),
                      child: Row(children: [
                        const Icon(Icons.lock_open, color: Colors.green),
                        const SizedBox(width: 10),
                        Text("ACCESS GRANTED",
                            style:
                                AppTheme.fontCode.copyWith(color: Colors.green))
                      ]),
                    ),
                    const SizedBox(height: 15),
                    if (widget.project.githubUrl != null)
                      GestureDetector(
                        onTap: () => _launchURL(widget.project.githubUrl!),
                        child: _ActionButton(
                          icon: PhosphorIcons.githubLogo(),
                          label: "VIEW SOURCE CODE",
                          color: isDark ? Colors.white : Colors.black,
                          isOutlined: true,
                        ),
                      ),
                    if (widget.project.githubUrl != null)
                      const SizedBox(height: 10),
                    if (widget.project.projectFileUrl != null)
                      GestureDetector(
                        onTap: () => _launchURL(widget.project.projectFileUrl!),
                        child: _ActionButton(
                          icon: PhosphorIcons.download(),
                          label: "DOWNLOAD PROJECT FILES",
                          color: AppTheme.neonBlue,
                          isOutlined: false,
                        ),
                      ),
                  ],

                  const SizedBox(height: 30),
                  Text("ACTIONS",
                      style:
                          theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      // REQUEST ACCESS BUTTON
                      Expanded(
                        child: GestureDetector(
                          onTap: _hasAccess || _requestSent
                              ? null
                              : _requestAccess,
                          child: _ActionButton(
                            icon: _hasAccess
                                ? PhosphorIcons.check()
                                : (_requestSent
                                    ? PhosphorIcons.clock()
                                    : PhosphorIcons.lockKey()),
                            label: _hasAccess
                                ? "UNLOCKED"
                                : (_requestSent
                                    ? "REQUESTED"
                                    : "REQUEST ACCESS"),
                            color: _hasAccess
                                ? Colors.grey
                                : (_requestSent
                                    ? Colors.orange
                                    : AppTheme.neonBlue),
                            isOutlined: _hasAccess,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // COMMENTS BUTTON
                      Expanded(
                        child: GestureDetector(
                          onTap: _showComments,
                          child: _ActionButton(
                            icon: PhosphorIcons.chatTeardropText(),
                            label: "COMMENTS",
                            color: isDark ? Colors.white : Colors.black,
                            isOutlined: true,
                          ),
                        ),
                      ),
                      // MESSAGE BUTTON (Only if not me)
                      if (!_isMe) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                          otherUser: widget.project.author)));
                            },
                            child: _ActionButton(
                              icon: PhosphorIcons.chatCircleDots(),
                              label: "MESSAGE",
                              color: AppTheme.neonBlue,
                              isOutlined: true,
                            ),
                          ),
                        ),
                      ]
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isOutlined;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      this.isOutlined = false});

  @override
  Widget build(BuildContext context) {
    Color contentColor = isOutlined ? color : Colors.black;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color,
        border: isOutlined ? Border.all(color: color.withOpacity(0.5)) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: contentColor, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: AppTheme.fontCode.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10)),
        ],
      ),
    );
  }
}
