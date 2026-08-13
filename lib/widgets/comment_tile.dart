import 'package:flutter/material.dart';
import '../models/comment.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdate;
  const CommentTile({
    super.key,
    required this.comment,
    this.onDelete,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: comment.userAvatar != null
            ? NetworkImage(comment.userAvatar!)
            : null,
        child: comment.userAvatar == null ? const Icon(Icons.person) : null,
      ),
      title: Text(comment.username ?? 'user'),
      subtitle: Text(comment.content),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onUpdate != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onUpdate,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
