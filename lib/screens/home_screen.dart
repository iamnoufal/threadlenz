import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

import 'image_picker_screen.dart';
import 'history_screen.dart';
import '../models/project_model.dart';
import '../services/storage_service.dart';
import 'package:universal_io/io.dart';
import 'project_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Use a key or just setState to rebuild logic
  // Simple way: just call setState when back

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ThreadLenz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
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
                      ).then((_) => setState(() {})); // Refresh on return
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
    return FutureBuilder<List<ProjectModel>>(
      future: StorageService().getRecentProjects(limit: 3),
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
                    child: project.generatedImagePaths.isNotEmpty
                        ? SizedBox(
                            width: 60,
                            height: 60,
                            child: _buildProjectThumb(project),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${project.generatedImagePaths.length} Variations',
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
          'Welcome back,',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.emeraldPrimary.withOpacity(0.7),
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
            color: AppTheme.emeraldPrimary.withOpacity(0.3),
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
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
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
                      color: AppTheme.emeraldPrimary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProjectThumb(ProjectModel project) {
    if (kIsWeb &&
        project.generatedImageBase64s != null &&
        project.generatedImageBase64s!.isNotEmpty) {
      final bytes = base64Decode(project.generatedImageBase64s!.first);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else if (!kIsWeb && project.generatedImagePaths.isNotEmpty) {
      return Image.file(
        File(project.generatedImagePaths.first),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    return const Icon(Icons.image);
  }
}
