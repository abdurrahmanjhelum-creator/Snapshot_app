import 'package:flutter/material.dart';
import 'profile_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(userId: userId);
  }
}
