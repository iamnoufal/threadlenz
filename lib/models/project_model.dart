class ProjectModel {
  final String id;
  final DateTime timestamp;
  final List<String> inputImagePaths;
  final List<String> generatedImagePaths;
  final List<String>? inputImageBase64s; // For Web
  final List<String>? generatedImageBase64s; // For Web
  final List<String> prompts;

  ProjectModel({
    required this.id,
    required this.timestamp,
    required this.inputImagePaths,
    required this.generatedImagePaths,
    this.inputImageBase64s,
    this.generatedImageBase64s,
    required this.prompts,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'inputImagePaths': inputImagePaths,
      'generatedImagePaths': generatedImagePaths,
      'inputImageBase64s': inputImageBase64s,
      'generatedImageBase64s': generatedImageBase64s,
      'prompts': prompts,
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      inputImagePaths: List<String>.from(json['inputImagePaths'] ?? []),
      generatedImagePaths: List<String>.from(json['generatedImagePaths'] ?? []),
      inputImageBase64s: json['inputImageBase64s'] != null
          ? List<String>.from(json['inputImageBase64s'])
          : null,
      generatedImageBase64s: json['generatedImageBase64s'] != null
          ? List<String>.from(json['generatedImageBase64s'])
          : null,
      prompts: List<String>.from(json['prompts']),
    );
  }
}
