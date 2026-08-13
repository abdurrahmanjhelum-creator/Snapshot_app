// FILE: feed_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/post_controller.dart';
import '../widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    // Feed fetch karne ke liye
    Future.microtask(() {
      if (mounted) {
        context.read<PostController>().fetchFeed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postCtrl = context.watch<PostController>();
    
    return Scaffold(
      appBar: AppBar(
        // Instagram title styled slightly
        title: const Text(
          'Instagram',
          style: TextStyle(
            fontFamily: 'Billabong', 
            fontSize: 32,
            fontWeight: FontWeight.w500
          ),
        ),
        centerTitle: false,
        actions: const [], // Purane buttons hata diye
      ),
      body: postCtrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => postCtrl.fetchFeed(),
        child: ListView.builder(
          itemCount: postCtrl.feedPosts.length,
          itemBuilder: (ctx, i) => PostCard(post: postCtrl.feedPosts[i]),
        ),
      ),
    );
  }
}
