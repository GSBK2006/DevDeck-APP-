class UserProfile {
  final String id;
  final String username;
  final String fullName;
  final String headline;
  final String avatarUrl;

  UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.headline,
    required this.avatarUrl,
  });
}

class Project {
  final String id;
  final String title;
  final String description;
  final List<String> techStack;
  final String author; // This corresponds to 'username'
  int votes;
  final String imageUrl;
  final DateTime createdAt;

  final String? githubUrl;
  final String? projectFileUrl;

  bool isAccessRequested;
  List<String> comments;
  List<String> permittedUsers;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.techStack,
    required this.author,
    this.votes = 0,
    required this.imageUrl,
    required this.createdAt,
    this.githubUrl,
    this.projectFileUrl,
    this.isAccessRequested = false,
    List<String>? comments,
    List<String>? permittedUsers,
  })  : comments = comments ?? [],
        permittedUsers = permittedUsers ?? [];
}

class InboxMessage {
  final String id;
  final String fromUser;
  final String projectTitle;
  final String projectId;
  final String status;
  final String type;

  InboxMessage({
    required this.id,
    required this.fromUser,
    required this.projectTitle,
    required this.projectId,
    required this.status,
    required this.type,
  });
}

// NEW: Chat Message Model
class ChatMessage {
  final String id;
  final String sender;
  final String receiver;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.createdAt,
  });
}

// Mock Data
List<Project> mockProjects = [];
