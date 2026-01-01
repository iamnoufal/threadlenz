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
      // WEB: Store as Base64 in the model (no file system)
      // For MVP Web: We generally skip saving large inputs to avoid hitting Quotas quickly
      // But we can try to save them if needed.
      // inputBase64s = [];
      // ... logic to read bytes ...

      generatedBase64s = generatedImageBytes
          .map((bytes) => base64Encode(bytes))
          .toList();
    } else {
      // MOBILE: Save to Disk
      final directory = await getApplicationDocumentsDirectory();

      // Save Input Images
      for (int i = 0; i < inputImages.length; i++) {
        final path = '${directory.path}/input_${timestampId}_$i.jpg';
        await inputImages[i].saveTo(path);
        inputPaths.add(path);
      }

      // Save Generated Images
      for (int i = 0; i < generatedImageBytes.length; i++) {
        final path = '${directory.path}/gen_${timestampId}_$i.jpg';
        final file = File(path);
        await file.writeAsBytes(generatedImageBytes[i]);
        generatedPaths.add(path);
      }
    }

    // Create Model
    final project = ProjectModel(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      inputImagePaths: inputPaths,
      generatedImagePaths: generatedPaths,
      inputImageBase64s: inputBase64s,
      generatedImageBase64s: generatedBase64s,
      prompts: prompts,
    );

    // Save Metadata to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final List<String> projectsJson = prefs.getStringList(_projectsKey) ?? [];

    // Limit storage on web to avoid quota issues
    int maxItems = kIsWeb ? 1 : 20;

    projectsJson.insert(0, jsonEncode(project.toJson()));
    if (projectsJson.length > maxItems) {
      projectsJson.length = maxItems;
    }

    await prefs.setStringList(_projectsKey, projectsJson);

    return project;
  }

  Future<List<ProjectModel>> getRecentProjects({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> projectsJson = prefs.getStringList(_projectsKey) ?? [];

    return projectsJson
        .take(limit)
        .map((str) => ProjectModel.fromJson(jsonDecode(str)))
        .toList();
  }

  Future<List<ProjectModel>> getAllProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> projectsJson = prefs.getStringList(_projectsKey) ?? [];

    return projectsJson
        .map((str) => ProjectModel.fromJson(jsonDecode(str)))
        .toList();
  }
}
