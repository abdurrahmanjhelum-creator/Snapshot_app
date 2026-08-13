// FILE: explore_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/post_grid_item.dart';
import 'user_profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Post> _results = [];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Keep existing followers fetch for other explore use-cases
    Future.microtask(() {
      if (mounted) {
        final auth = context.read<AuthController>();
        if (auth.user != null) {
          context.read<UserController>().fetchFollowers(auth.user!.id);
        }
      }
    });
    _searchController.addListener(() {
      // No-op here; we rely on onChanged below to control debounce
    });
  }

  @override
  Widget build(BuildContext context) {
    final userCtrl = context.watch<UserController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Search input is already in AppBar; keep a small spacer area for results
            Expanded(
              child: _buildSearchBody(userCtrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBody(UserController userCtrl) {
    // Initial empty query state
    if (_query.trim().isEmpty) {
      return Center(
        child: Text(
          'Type to search posts live...',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 12),
            const Text('No posts found'),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final post = _results[index];
        return PostGridItem(
          post: post,
          onPostDeleted: () {
            // remove from results if deleted
            setState(() => _results.removeWhere((p) => p.id == post.id));
          },
        );
      },
    );
  }

  void _onSearchChanged(String val) {
    _query = val;
    _debounce?.cancel();
    if (val.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(val.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.searchPosts(query);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic> list = data['posts'] ?? data['results'] ?? [];
        setState(() {
          _results = list.map((e) => Post.fromJson(e)).toList();
        });
      } else {
        setState(() => _results = []);
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
