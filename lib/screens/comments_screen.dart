import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

import '../models/comment.dart';

import '../services/api_service.dart';
import '../services/socket_service.dart';

import '../widgets/comment_tile.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  List<Comment> _comments = [];

  bool _loading = true;

  final _msgCtrl = TextEditingController();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();

    _fetchComments();
    _initializeSocket();
  }

  void _initializeSocket() {
    _socketService.connect();
    _socketService.joinPost(widget.postId);

    // Listen for new comments
    _socketService.on('comment-added', (data) {
      final commentData = data['comment'];
      if (commentData != null && mounted) {
        setState(() {
          _comments.insert(0, Comment.fromJson(commentData));
        });
      }
    });

    // Listen for deleted comments
    _socketService.on('comment-deleted', (data) {
      final commentId = data['commentId'] as String;
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c.id == commentId);
        });
      }
    });

    // Listen for updated comments
    _socketService.on('comment-updated', (data) {
      final commentData = data['comment'];
      if (commentData != null && mounted) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == commentData['_id']);
          if (index != -1) {
            _comments[index] = Comment.fromJson(commentData);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _socketService.leavePost(widget.postId);
    _socketService.off('comment-added');
    _socketService.off('comment-deleted');
    _socketService.off('comment-updated');
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final res = await ApiService.getComments(widget.postId);

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        List<dynamic> list = data['comments'] ?? [];

        if (mounted) {
          setState(
            () => _comments = list.map((e) => Comment.fromJson(e)).toList(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addComment() async {
    final content = _msgCtrl.text.trim();

    if (content.isEmpty) return;

    await ApiService.addComment(widget.postId, content);

    _msgCtrl.clear();

    _fetchComments();
  }

  Future<void> _deleteComment(String commentId) async {
    await ApiService.deleteComment(commentId);

    _fetchComments();
  }

  Future<void> _updateComment(Comment comment) async {
    final TextEditingController editCtrl = TextEditingController(
      text: comment.content,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editCtrl,
          decoration: const InputDecoration(hintText: 'Edit your comment...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editCtrl.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ApiService.updateComment(comment.id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Comments')),

      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _comments.length,

                    itemBuilder: (ctx, i) => CommentTile(
                      comment: _comments[i],

                      onDelete:
                          _comments[i].userId ==
                              context.read<AuthController>().user?.id
                          ? () => _deleteComment(_comments[i].id)
                          : null,
                      onUpdate:
                          _comments[i].userId ==
                              context.read<AuthController>().user?.id
                          ? () => _updateComment(_comments[i])
                          : null,
                    ),
                  ),
          ),

          Padding(
            padding: EdgeInsets.all(8.0),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(hintText: 'Add a comment...'),
                  ),
                ),

                IconButton(icon: Icon(Icons.send), onPressed: _addComment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
