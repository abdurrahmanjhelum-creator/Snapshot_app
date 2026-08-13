import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb ke liye
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  
  Uint8List? _webImage; // For web and preview bytes
  XFile? _pickedFile;
  bool _imageChanged = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // AuthController se user data le kar controllers fill karna
    final user = context.read<AuthController>().user;
    if (user != null) {
      _usernameCtrl.text = user.username;
      _bioCtrl.text = user.bio ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedFile = image;
        _webImage = bytes;
        _imageChanged = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    final userCtrl = context.read<UserController>();
    final authCtrl = context.read<AuthController>();

    // API call through controller
    final error = await userCtrl.updateProfile(
      username: _usernameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      imageBytes: _imageChanged ? _webImage : null,
      fileName: _imageChanged ? _pickedFile?.name : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      // Success: Refresh local auth user data and pop
      await authCtrl.refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      // Error show karna
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthController>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          _isSaving 
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            : IconButton(onPressed: _saveProfile, icon: const Icon(Icons.check, color: Colors.blue)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar Preview Area
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageChanged && _webImage != null
                          ? MemoryImage(_webImage!) // State 3: New image picked
                          : (user?.avatar != null && user!.avatar!.isNotEmpty)
                              ? NetworkImage(ApiService.getImageUrl(user.avatar)) // State 2: Existing image
                              : null, // State 1: No image
                      child: (!_imageChanged && (user?.avatar == null || user!.avatar!.isEmpty))
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username', border: UnderlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bioCtrl,
              decoration: const InputDecoration(labelText: 'Bio', border: UnderlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
