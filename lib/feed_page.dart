import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'data.dart';
import 'card.dart';
import 'login_page.dart';
import 'upload_page.dart';
import 'inbox_page.dart';
import 'chat_page.dart';
import 'create_profile_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Project> _projects = [];
  bool _isLoading = true;
  String _searchQuery = "";
  int _notificationCount = 0;

  int _myProjectCount = 0;

  Set<String> _followingList = {};
  Map<String, int> _unreadCounts = {};
  Set<String> _uniqueAuthors = {};

  late Timer _timer;
  String _currentTime = "";
  String _greeting = "";
  String _myUsername = "";

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _myUsername = user?.email?.split('@')[0] ?? 'User';

    _setupTime();
    _fetchFollowingData();
    _fetchProjects();
    _fetchNotificationCount();
  }

  void _setupTime() {
    _updateTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = "Good Night";
    if (hour >= 5 && hour < 12)
      greeting = "Good Morning";
    else if (hour >= 12 && hour < 17)
      greeting = "Good Afternoon";
    else if (hour >= 17 && hour < 21) greeting = "Good Evening";

    if (mounted) {
      setState(() {
        _currentTime = DateFormat('hh : mm : ss a').format(now);
        _greeting = greeting;
      });
    }
  }

  // --- SETTINGS MODAL (FIXED SCROLL) ---
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow it to take up more space if needed
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return StatefulBuilder(builder: (context, setState) {
                return SingleChildScrollView(
                  // <--- THE FIX: Makes content scrollable
                  controller: scrollController,
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2))),
                      ),
                      Text("APPEARANCE",
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 20),

                      // Color Theme Picker
                      Text("Theme Color",
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 15,
                        runSpacing: 10,
                        children: AppTheme.colorOptions.map((color) {
                          bool isSelected =
                              AppTheme.primaryColorNotifier.value == color;
                          return GestureDetector(
                            onTap: () {
                              AppTheme.primaryColorNotifier.value = color;
                              setState(() {});
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 8)
                                  ]),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Dark Mode Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Dark Mode",
                              style: Theme.of(context).textTheme.bodyLarge),
                          Switch(
                            value: AppTheme.isDarkNotifier.value,
                            activeColor: AppTheme.neonBlue,
                            onChanged: (val) {
                              AppTheme.isDarkNotifier.value = val;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      const Divider(),

                      // Font Selector
                      Text("Font Style",
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppTheme.fontOptions.entries.map((entry) {
                          return _buildFontOption(
                              entry.key, entry.value, setState);
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Font Size Slider
                      Text("Text Size",
                          style: Theme.of(context).textTheme.bodyMedium),
                      Slider(
                        value: AppTheme.fontScaleNotifier.value,
                        min: 0.8,
                        max: 1.4,
                        activeColor: AppTheme.neonBlue,
                        onChanged: (val) {
                          AppTheme.fontScaleNotifier.value = val;
                          setState(() {});
                        },
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonBlue,
                              foregroundColor: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("CLOSE"),
                        ),
                      )
                    ],
                  ),
                );
              });
            });
      },
    );
  }

  Widget _buildFontOption(String label, String font, StateSetter setState) {
    bool isSelected = AppTheme.fontFamilyNotifier.value == font;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontFamily: font)),
      selected: isSelected,
      selectedColor: AppTheme.neonBlue.withOpacity(0.3),
      onSelected: (val) {
        if (val) {
          AppTheme.fontFamilyNotifier.value = font;
          setState(() {});
        }
      },
    );
  }

  Future<void> _fetchNotificationCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('to_user', user.email!)
        .listen((data) {
          if (mounted)
            setState(() => _notificationCount = data
                .where(
                    (n) => n['status'] == 'pending' || n['status'] == 'unread')
                .length);
        });
  }

  Future<void> _fetchFollowingData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final response = await Supabase.instance.client
        .from('follows')
        .select('following_username')
        .eq('follower_id', user.id);
    if (mounted)
      setState(() => _followingList = (response as List)
          .map((e) => e['following_username'].toString())
          .toSet());
  }

  Future<void> _toggleFollow(String targetUsername) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() {
      if (_followingList.contains(targetUsername)) {
        _followingList.remove(targetUsername);
      } else {
        _followingList.add(targetUsername);
      }
    });
    try {
      if (!_followingList.contains(targetUsername)) {
        await Supabase.instance.client
            .from('follows')
            .delete()
            .eq('follower_id', user.id)
            .eq('following_username', targetUsername);
      } else {
        await Supabase.instance.client.from('follows').insert(
            {'follower_id': user.id, 'following_username': targetUsername});
      }
      _fetchProjects();
    } catch (e) {
      debugPrint("Follow Error: $e");
    }
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userEmail = user?.email?.split('@')[0] ?? '';

      final response = await Supabase.instance.client
          .from('projects')
          .select()
          .order('created_at', ascending: false);
      final data = response as List<dynamic>;

      final allProjects = data.map((json) {
        DateTime serverTime =
            DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
        // Force IST
        DateTime istTime =
            serverTime.toUtc().add(const Duration(hours: 5, minutes: 30));
        return Project(
          id: json['id'].toString(),
          title: json['title'] ?? 'Untitled',
          description: json['description'] ?? '',
          techStack: List<String>.from(json['tech_stack'] ?? []),
          author: json['author'] ?? 'Anon',
          votes: json['votes'] ?? 0,
          imageUrl: json['image_url'] ?? 'https://via.placeholder.com/400x200',
          createdAt: istTime,
          permittedUsers: List<String>.from(json['permitted_users'] ?? []),
          comments: List<String>.from(json['comments'] ?? []),
          githubUrl: json['github_url'],
          projectFileUrl: json['project_file_url'],
        );
      }).toList();

      final authors = allProjects.map((p) => p.author).toSet();
      authors.remove(userEmail);
      _uniqueAuthors = authors;

      allProjects.sort((a, b) {
        bool aFollowed = _followingList.contains(a.author);
        bool bFollowed = _followingList.contains(b.author);
        if (aFollowed && !bFollowed) return -1;
        if (!aFollowed && bFollowed) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      setState(() {
        _projects = allProjects;
        _myProjectCount =
            allProjects.where((p) => p.author == userEmail).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateAndRefresh() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const UploadPage()));
    if (result == true) {
      _fetchProjects();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
        valueListenable: AppTheme.primaryColorNotifier,
        builder: (context, primaryColor, _) {
          bool isDark = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboardTab(isDark),
                _buildSocialTab(isDark),
                _buildChatTab(isDark),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              height: 65,
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _currentIndex = idx),
              backgroundColor: Theme.of(context).cardColor,
              elevation: 10,
              indicatorColor: AppTheme.neonBlue.withOpacity(0.2),
              destinations: [
                NavigationDestination(
                    icon: Icon(PhosphorIcons.house()),
                    selectedIcon:
                        Icon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
                    label: 'Feed'),
                NavigationDestination(
                    icon: Icon(PhosphorIcons.users()),
                    selectedIcon:
                        Icon(PhosphorIcons.users(PhosphorIconsStyle.fill)),
                    label: 'Network'),
                NavigationDestination(
                    icon: Stack(
                      children: [
                        Icon(PhosphorIcons.chatCircle()),
                        if (_unreadCounts.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle)),
                          )
                      ],
                    ),
                    selectedIcon:
                        Icon(PhosphorIcons.chatCircle(PhosphorIconsStyle.fill)),
                    label: 'Chat'),
              ],
            ),
            floatingActionButton: _currentIndex == 0
                ? FloatingActionButton(
                    backgroundColor: AppTheme.neonBlue,
                    child: const Icon(Icons.add, color: Colors.white),
                    onPressed: _navigateAndRefresh,
                  )
                : null,
          );
        });
  }

  Widget _buildDashboardTab(bool isDark) {
    final filteredProjects = _projects.where((p) {
      final title = p.title.toLowerCase();
      final author = p.author.toLowerCase();
      return title.contains(_searchQuery) || author.contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon:
                        Icon(PhosphorIcons.gearSix(), color: AppTheme.neonBlue),
                    onPressed: _showSettings,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(PhosphorIcons.envelopeSimple(),
                            color: AppTheme.neonBlue),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const InboxPage())),
                      ),
                      IconButton(
                        icon: Icon(PhosphorIcons.signOut(),
                            color: Colors.redAccent),
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (mounted)
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()));
                        },
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting,
                          style: AppTheme.fontTech.copyWith(
                              fontSize: 32,
                              color: AppTheme.neonBlue,
                              height: 1.0)),
                      Text("$_myUsername",
                          style: AppTheme.fontCode
                              .copyWith(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  Text(_currentTime,
                      style: AppTheme.fontCode.copyWith(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  _buildStatCard(
                      "PROJECTS", _myProjectCount.toString(), isDark),
                  const SizedBox(width: 10),
                  _buildStatCard(
                      "FOLLOWING", _followingList.length.toString(), isDark),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _searchController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    icon: Icon(PhosphorIcons.magnifyingGlass(),
                        size: 20, color: Colors.grey),
                    hintText: "Search projects...",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppTheme.neonBlue))
              : filteredProjects.isEmpty
                  ? Center(
                      child: Text("No Projects Found",
                          style: Theme.of(context).textTheme.bodyMedium))
                  : RefreshIndicator(
                      onRefresh: _fetchProjects,
                      color: AppTheme.neonBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = filteredProjects[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 25),
                            child: ProjectCard(project: project),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
            ]),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppTheme.neonBlue)),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialTab(bool isDark) {
    final users = _uniqueAuthors.toList();
    return Scaffold(
      appBar: AppBar(
          title: const Text("NETWORK"),
          backgroundColor: Colors.transparent,
          centerTitle: true),
      body: users.isEmpty
          ? const Center(child: Text("No users found."))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: users.length,
              separatorBuilder: (c, i) => const SizedBox(height: 15),
              itemBuilder: (ctx, index) {
                final user = users[index];
                final isFollowing = _followingList.contains(user);
                return ListTile(
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: CircleAvatar(child: Text(user[0].toUpperCase())),
                  title:
                      Text(user, style: Theme.of(context).textTheme.bodyLarge),
                  trailing: ElevatedButton(
                    onPressed: () => _toggleFollow(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isFollowing ? Colors.transparent : AppTheme.neonBlue,
                      foregroundColor: isFollowing
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.white,
                    ),
                    child: Text(isFollowing ? "Unfollow" : "Follow"),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildChatTab(bool isDark) {
    final contacts = _followingList.toList();
    return Scaffold(
      appBar: AppBar(
          title: const Text("MESSAGES"),
          backgroundColor: Colors.transparent,
          centerTitle: true),
      body: contacts.isEmpty
          ? const Center(child: Text("Follow someone to chat."))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: contacts.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (ctx, index) {
                final username = contacts[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(username[0].toUpperCase())),
                  title: Text(username,
                      style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChatPage(otherUser: username))),
                );
              },
            ),
    );
  }
}
