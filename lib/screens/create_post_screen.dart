import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/post_controller.dart';
import '../controllers/auth_controller.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Image handling variables
  Uint8List? _imageBytes; // Web + Mobile compatible
  String? _fileName; // Required for API

  bool _isUploading = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // Pick Image Logic
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _fileName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error picking image: $e", isError: true);
    }
  }

  // Upload Logic
  Future<void> _submitPost() async {
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();

    if (_imageBytes == null) {
      _showSnackBar("Please select an image", isError: true);
      return;
    }
    if (title.isEmpty) {
      _showSnackBar("Title is required", isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final postController = Provider.of<PostController>(
        context,
        listen: false,
      );

      final error = await postController.createPost(
        title,
        description.isEmpty ? null : description,
        _imageBytes!,
        _fileName ?? "post_image.jpg",
      );

      if (!mounted) return;

      if (error == null) {
        _showSnackBar("Post created successfully!", isError: false);
        // Refresh current user profile to update postCount
        await context.read<AuthController>().refreshUser();
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar(error, isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Something went wrong: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "New Post",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _submitPost,
            child: const Text(
              "Share",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Tap to select image",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "Write a title...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Write a description (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
