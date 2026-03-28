import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import '../models/project_model.dart';
import 'package:uuid/uuid.dart';
import 'package:cross_file/cross_file.dart';

class StorageService {
  static const String _projectsKey = 'recent_projects';
  final Uuid _uuid = const Uuid();

  Future<ProjectModel> saveProject({
    required List<String> prompts,
    required List<XFile> inputImages,
    required List<Uint8List> generatedImageBytes,
  }) async {
    final String timestampId = DateTime.now().millisecondsSinceEpoch.toString();
    List<String> inputPaths = [];
    List<String> generatedPaths = [];
    List<String>? inputBase64s;
    List<String>? generatedBase64s;

    if (kIsWeb) {
      generatedBase64s = generatedImageBytes
          .map((bytes) => base64Encode(bytes))
          .toList();
    } else {
      final directory = await getApplicationDocumentsDirectory();

      for (int i = 0; i < inputImages.length; i++) {
        final path = '${directory.path}/input_${timestampId}_$i.jpg';
        await inputImages[i].saveTo(path);
        inputPaths.add(path);
      }

      for (int i = 0; i < generatedImageBytes.length; i++) {
        final path = '${directory.path}/gen_${timestampId}_$i.jpg';
        final file = File(path);
        await file.writeAsBytes(generatedImageBytes[i]);
        generatedPaths.add(path);
      }
    }

    final project = ProjectModel(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      inputImagePaths: inputPaths,
      generatedImagePaths: generatedPaths,
      inputImageBase64s: inputBase64s,
      generatedImageBase64s: generatedBase64s,
      prompts: prompts,
    );

    final prefs = await SharedPreferences.getInstance();
    final List<String> projectsJson = prefs.getStringList(_projectsKey) ?? [];

    int maxItems = kIsWeb ? 1 : 20;

    projectsJson.insert(0, jsonEncode(project.toJson()));
    if (projectsJson.length > maxItems) {
      projectsJson.length = maxItems;
    }

    await prefs.setStringList(_projectsKey, projectsJson);

    return project;
  }

  /// Adds a new generated image to an existing project.
  Future<void> addGeneratedImage({
    required String projectId,
    required Uint8List imageBytes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> projectsJson = prefs.getStringList(_projectsKey) ?? [];

    for (int i = 0; i < projectsJson.length; i++) {
      final json = jsonDecode(projectsJson[i]) as Map<String, dynamic>;
      if (json['id'] == projectId) {
        if (kIsWeb) {
          final base64List = List<String>.from(json['generatedImageBase64s'] ?? []);
          base64List.add(base64Encode(imageBytes));
          json['generatedImageBase64s'] = base64List;
        } else {
          final directory = await getApplicationDocumentsDirectory();
          final paths = List<String>.from(json['generatedImagePaths'] ?? []);
          final timestampId = DateTime.now().millisecondsSinceEpoch.toString();
          final path = '${directory.path}/gen_${timestampId}_${paths.length}.jpg';
          final file = File(path);
          await file.writeAsBytes(imageBytes);
          paths.add(path);
          json['generatedImagePaths'] = paths;
        }

        projectsJson[i] = jsonEncode(json);
        await prefs.setStringList(_projectsKey, projectsJson);
        return;
      }
    }
  }

  Future<List<ProjectModel>> getRecentProjects({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> projectsJson = prefs.getStringList(_projectsKey) ?? [];

    return projectsJson
        .take(limit)
        .map((str) => ProjectModel.fromJson(jsonDecode(str)))
        .toList();
  }

  Future<void> deleteProject(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> projectsJson = prefs.getStringList(_projectsKey) ?? [];

    ProjectModel? projectToDelete;
    projectsJson.removeWhere((str) {
      final project = ProjectModel.fromJson(jsonDecode(str));
      if (project.id == projectId) {
        projectToDelete = project;
        return true;
      }
      return false;
    });

    await prefs.setStringList(_projectsKey, projectsJson);

    if (!kIsWeb && projectToDelete != null) {
      for (final path in projectToDelete!.inputImagePaths) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      for (final path in projectToDelete!.generatedImagePaths) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
  }

  Future<List<ProjectModel>> getAllProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> projectsJson = prefs.getStringList(_projectsKey) ?? [];

    return projectsJson
        .map((str) => ProjectModel.fromJson(jsonDecode(str)))
        .toList();
  }
}
