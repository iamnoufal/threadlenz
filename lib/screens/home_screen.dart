import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

import 'image_picker_screen.dart';
import 'history_screen.dart';
import '../models/project_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'project_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();

  String get _userName =>
      _authService.currentUser?.displayName ?? 'Creator';
  String? get _userPhotoUrl => _authService.currentUser?.photoURL;
  String? get _uid => _authService.currentUser?.uid;

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.signOut();
      // AuthGate's StreamBuilder will detect the auth state change
      // and automatically navigate to AuthScreen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ThreadLenz'),
        actions: [
          if (_uid != null)
            FutureBuilder<int>(
              future: FirestoreService().getTokenBalance(_uid!),
              builder: (context, snapshot) {
                final balance = snapshot.data ?? 0;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.goldAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.token,
                        size: 16,
                        color: AppTheme.goldAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$balance',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.emeraldPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (_userPhotoUrl != null)
            GestureDetector(
              onTap: _signOut,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: CachedNetworkImageProvider(_userPhotoUrl!),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 32),
              _buildStartProjectCard(context),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Projects',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRecentProjectsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentProjectsList() {
    if (_uid == null) {
      return _buildRecentProjectsPlaceholder();
    }

    return FutureBuilder<List<ProjectModel>>(
      future: FirestoreService().getProjects(_uid!, limit: 3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildRecentProjectsPlaceholder(isLoading: true);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildRecentProjectsPlaceholder();
        }

        final projects = snapshot.data!;
        return Column(
          children: projects.map((project) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProjectDetailScreen(project: project),
                    ),
                  ).then((_) => setState(() {}));
                },
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: project.generatedImageUrls.isNotEmpty
                        ? SizedBox(
                            width: 60,
                            height: 60,
                            child: CachedNetworkImage(
                              imageUrl: project.generatedImageUrls.first,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, _, _) =>
                                  const Icon(Icons.broken_image),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image),
                          ),
                  ),
                  title: Text(
                    project.prompts.isNotEmpty
                        ? project.prompts.first
                        : 'Untitled',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                  ),
                  subtitle: Text(
                    '${project.generatedImageUrls.length} Variations',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $_userName',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.emeraldPrimary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create Stunning\nProduct Photos',
          style: TextStyle(
            fontSize: 32,
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.bold,
            color: AppTheme.emeraldPrimary,
            height: 1.1,
          ),
        ).animate().fadeIn().slideX(),
      ],
    );
  }

  Widget _buildStartProjectCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.emeraldPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emeraldPrimary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ImagePickerScreen(),
              ),
            ).then((_) => setState(() {}));
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.goldAccent,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'New Project',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload photos & let AI do the magic',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildRecentProjectsPlaceholder({bool isLoading = false}) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softGrey),
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: AppTheme.emeraldPrimary)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: AppTheme.softGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No projects yet',
                    style: TextStyle(
                      color: AppTheme.emeraldPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
