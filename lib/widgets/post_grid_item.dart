import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../screens/full_post_view.dart';

class PostGridItem extends StatelessWidget {
  final Post post;
  final VoidCallback? onPostDeleted;
  const PostGridItem({super.key, required this.post, this.onPostDeleted});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Navigate to full post view and await result
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FullPostView(post: post)),
        );
        // If post was deleted, trigger callback
        if (result == true && onPostDeleted != null) {
          onPostDeleted!();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: post.image != null && post.image!.isNotEmpty
            ? Image.network(
                ApiService.getImageUrl(post.image),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 30),
                ),
              )
            : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 30),
              ),
      ),
    );
  }
}
