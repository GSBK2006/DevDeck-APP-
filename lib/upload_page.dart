import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'theme.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _techController = TextEditingController();
  final _githubController = TextEditingController();

  String? _selectedImage;
  String? _projectFileUrl;
  bool isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileExt = image.path.split('.').last;
        final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
        final filePath = '/$fileName';

        await Supabase.instance.client.storage.from('images').uploadBinary(
            filePath, bytes,
            fileOptions: FileOptions(contentType: image.mimeType));

        final imageUrl = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(filePath);

        setState(() => _selectedImage = imageUrl);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Upload Error: $e"), backgroundColor: Colors.red));
      } finally {
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() => isUploading = true);
      try {
        final file = result.files.first;
        final bytes = file.bytes;
        final fileName = file.name;
        final filePath = '/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        if (bytes != null) {
          await Supabase.instance.client.storage
              .from('files')
              .uploadBinary(filePath, bytes);

          final fileUrl = Supabase.instance.client.storage
              .from('files')
              .getPublicUrl(filePath);

          setState(() => _projectFileUrl = fileUrl);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Upload Error: $e"), backgroundColor: Colors.red));
      } finally {
        setState(() => isUploading = false);
      }
    }
  }

  void _showUrlInputDialog(Function(String) onConfirm) {
    showDialog(
        context: context,
        builder: (ctx) {
          final urlController = TextEditingController();
          return AlertDialog(
            backgroundColor: AppTheme.cardBg,
            title: Text("PASTE URL", style: AppTheme.fontTech),
            content: TextField(
              controller: urlController,
              style: AppTheme.fontCode.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: "https://...",
                  hintStyle: TextStyle(color: Colors.white24)),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("CANCEL")),
              TextButton(
                  onPressed: () {
                    if (urlController.text.isNotEmpty) {
                      onConfirm(urlController.text);
                      Navigator.pop(ctx);
                    }
                  },
                  // Fixed: Removed const
                  child:
                      Text("USE", style: TextStyle(color: AppTheme.neonBlue)))
            ],
          );
        });
  }

  Future<void> _mintCard() async {
    if (_titleController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Title and Image are required!")));
      return;
    }

    setState(() => isUploading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final authorEmail = user?.email?.split('@')[0] ?? 'Anon';

      await Supabase.instance.client.from('projects').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'tech_stack':
            _techController.text.split(',').map((e) => e.trim()).toList(),
        'author': authorEmail,
        'image_url': _selectedImage,
        'github_url':
            _githubController.text.isNotEmpty ? _githubController.text : null,
        'project_file_url': _projectFileUrl,
        'votes': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("PROJECT MINTED SUCCESSFULLY",
              style: AppTheme.fontCode.copyWith(color: Colors.black)),
          backgroundColor: AppTheme.neonBlue,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("MINT NEW CARD",
            style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        iconTheme:
            IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputLabel("PROJECT TITLE", context),
            _buildInputField(
                _titleController, "Enter project name...", context),
            const SizedBox(height: 20),
            _buildInputLabel("DESCRIPTION", context),
            _buildInputField(_descController, "What does it do?", context,
                maxLines: 4),
            const SizedBox(height: 20),
            _buildInputLabel("ATTRIBUTES (TECH STACK)", context),
            _buildInputField(_techController,
                "Flutter, Firebase, AI (Comma separated)", context),
            const SizedBox(height: 20),
            _buildInputLabel("GITHUB REPOSITORY (OPTIONAL)", context),
            _buildInputField(
                _githubController, "https://github.com/user/repo", context),
            const SizedBox(height: 20),
            _buildInputLabel("PROJECT FILES (OPTIONAL)", context),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickAndUploadFile,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade200,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.uploadSimple(),
                              color: _projectFileUrl != null
                                  ? Colors.green
                                  : Colors.grey),
                          const SizedBox(width: 10),
                          Text(
                              _projectFileUrl != null
                                  ? "FILE UPLOADED"
                                  : "UPLOAD LOCAL FILE",
                              style: AppTheme.fontCode.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showUrlInputDialog(
                        (url) => setState(() => _projectFileUrl = url)),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade200,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.googleDriveLogo(),
                              color: Colors.blue),
                          const SizedBox(width: 10),
                          Text("DRIVE LINK",
                              style: AppTheme.fontCode.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInputLabel("THEME PREVIEW IMAGE", context),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black26),
                          borderRadius: BorderRadius.circular(12),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: NetworkImage(_selectedImage!),
                                  fit: BoxFit.cover)
                              : null),
                      child: _selectedImage == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIcons.image(),
                                      color:
                                          isDark ? Colors.white54 : Colors.grey,
                                      size: 30),
                                  const SizedBox(height: 8),
                                  Text("TAP TO UPLOAD",
                                      style: AppTheme.fontCode.copyWith(
                                          color: isDark
                                              ? Colors.white30
                                              : Colors.grey)),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonBlue,
                    foregroundColor: Colors.black),
                onPressed: isUploading ? null : _mintCard,
                child: isUploading
                    ? const CircularProgressIndicator()
                    : Text("MINT PROJECT CARD",
                        style: AppTheme.fontTech.copyWith(color: Colors.black)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text, BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text,
          style: AppTheme.fontCode
              .copyWith(color: AppTheme.neonBlue, fontSize: 12)));

  Widget _buildInputField(
      TextEditingController controller, String hint, BuildContext context,
      {int maxLines = 1}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8)),
      child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: isDark ? Colors.white24 : Colors.black38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16))),
    );
  }
}
