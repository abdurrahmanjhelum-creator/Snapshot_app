import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import 'user_profile_screen.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;
  const FollowingScreen({super.key, required this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<UserController>().fetchFollowing(widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UserController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Following')),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: ctrl.following.length,
        itemBuilder: (ctx, i) {
          final user = ctrl.following[i];
          return ListTile(
            leading: CircleAvatar(backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null),
            title: Text(user.username),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id))),
          );
        },
      ),
    );
  }
}
