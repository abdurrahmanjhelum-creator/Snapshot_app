import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import 'user_profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  const FollowersScreen({super.key, required this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<UserController>().fetchFollowers(widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UserController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Followers')),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: ctrl.followers.length,
        itemBuilder: (ctx, i) {
          final user = ctrl.followers[i];
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
