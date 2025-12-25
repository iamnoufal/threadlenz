import 'package:universal_io/io.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';

import '../models/project_model.dart';
import '../services/storage_service.dart';
import 'project_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ProjectModel> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final projects = await StorageService().getAllProjects();
    if (mounted) {
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
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
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (project.generatedImagePaths.isNotEmpty)
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: _buildProjectImage(project, 0),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${project.generatedImagePaths.length} variations • ${project.timestamp.toString().split('.')[0]}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
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

  Widget _buildProjectImage(ProjectModel project, int index) {
    // Check if Web and has base64
    if (kIsWeb &&
        project.generatedImageBase64s != null &&
        index < project.generatedImageBase64s!.length) {
      final bytes = base64Decode(project.generatedImageBase64s![index]);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else if (!kIsWeb && index < project.generatedImagePaths.length) {
      return Image.file(
        File(project.generatedImagePaths[index]),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    return const Icon(Icons.image_not_supported);
  }
}
