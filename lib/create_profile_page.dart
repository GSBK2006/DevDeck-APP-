import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'feed_page.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  // Removed Username Controller
  final _fullNameController = TextEditingController();
  final _headlineController = TextEditingController();
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          // Only load Name and Headline
          _fullNameController.text = data['full_name'] ?? '';
          _headlineController.text = data['headline'] ?? '';
          _avatarUrl = data['avatar_url'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileExt = image.path.split('.').last;
        final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
        final filePath = '/avatars/$fileName';

        await Supabase.instance.client.storage.from('images').uploadBinary(
            filePath, bytes,
            fileOptions: FileOptions(contentType: image.mimeType));

        final url = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(filePath);

        setState(() => _avatarUrl = url);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Upload Error: $e"), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Full Name is required")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Auto-generate username from email prefix
      final autoUsername = user.email?.split('@')[0] ?? 'anon';

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'username': autoUsername, // Automatically set
        'full_name': _fullNameController.text.trim(),
        'headline': _headlineController.text.trim(),
        'avatar_url': _avatarUrl ?? 'https://via.placeholder.com/150',
      });

      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const FeedPage()));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("EDIT PROFILE", style: AppTheme.fontTech),
          backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade800,
                backgroundImage:
                    _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null
                    ? Icon(PhosphorIcons.camera(),
                        size: 30, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text("Tap to Change Photo",
                style: AppTheme.fontCode.copyWith(color: Colors.grey)),
            const SizedBox(height: 30),

            _buildInput("FULL NAME", _fullNameController),
            const SizedBox(height: 20),
            // Username field removed
            _buildInput("HEADLINE (Bio)", _headlineController, maxLines: 3),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonBlue,
                    foregroundColor: Colors.black),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text("SAVE PROFILE",
                        style: AppTheme.fontTech.copyWith(color: Colors.black)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.fontCode
                .copyWith(color: AppTheme.neonBlue, fontSize: 12)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: AppTheme.fontTech.copyWith(color: Colors.white),
            decoration: const InputDecoration(
                border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
          ),
        )
      ],
    );
  }
}
