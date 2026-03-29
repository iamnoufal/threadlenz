import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/project_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/cloud_storage_service.dart';
import 'project_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ProjectModel> _projects = [];
  bool _isLoading = true;

  String? get _uid => AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final projects = await FirestoreService().getProjects(_uid!);
    if (mounted) {
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProject(ProjectModel project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text(
          'This will permanently delete this project and all its images. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && _uid != null) {
      // Delete from Storage and Firestore
      await CloudStorageService().deleteProjectFiles(
        uid: _uid!,
        projectId: project.id,
      );
      await FirestoreService().deleteProject(_uid!, project.id);
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? const Center(child: Text('No projects yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
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
                          ).then((_) => _loadHistory());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (project.generatedImageUrls.isNotEmpty)
                              SizedBox(
                                height: 150,
                                width: double.infinity,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      project.generatedImageUrls.first,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, _, _) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project.prompts.isNotEmpty
                                              ? project.prompts.first
                                              : 'Untitled Project',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${project.generatedImageUrls.length} variations \u2022 ${project.timestamp.toString().split('.')[0]}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _deleteProject(project),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Delete project',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
