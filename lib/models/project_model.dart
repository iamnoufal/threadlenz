class ProjectModel {
  final String id;
  final String? userId;
  final DateTime timestamp;
  final List<String> inputImagePaths;
  final List<String> generatedImagePaths;
  final List<String>? inputImageBase64s; // For Web
  final List<String>? generatedImageBase64s; // For Web
  final List<String> inputImageUrls; // Firebase Storage URLs
  final List<String> generatedImageUrls; // Firebase Storage URLs
  final List<String> prompts;

  ProjectModel({
    required this.id,
    this.userId,
    required this.timestamp,
    required this.inputImagePaths,
    required this.generatedImagePaths,
    this.inputImageBase64s,
    this.generatedImageBase64s,
    this.inputImageUrls = const [],
    this.generatedImageUrls = const [],
    required this.prompts,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'inputImagePaths': inputImagePaths,
      'generatedImagePaths': generatedImagePaths,
      'inputImageBase64s': inputImageBase64s,
      'generatedImageBase64s': generatedImageBase64s,
      'inputImageUrls': inputImageUrls,
      'generatedImageUrls': generatedImageUrls,
      'prompts': prompts,
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      inputImagePaths: List<String>.from(json['inputImagePaths'] ?? []),
      generatedImagePaths: List<String>.from(json['generatedImagePaths'] ?? []),
      inputImageBase64s: json['inputImageBase64s'] != null
          ? List<String>.from(json['inputImageBase64s'])
          : null,
      generatedImageBase64s: json['generatedImageBase64s'] != null
          ? List<String>.from(json['generatedImageBase64s'])
          : null,
      inputImageUrls: List<String>.from(json['inputImageUrls'] ?? []),
      generatedImageUrls: List<String>.from(json['generatedImageUrls'] ?? []),
      prompts: List<String>.from(json['prompts'] ?? []),
    );
  }

  ProjectModel copyWith({
    List<String>? inputImageUrls,
    List<String>? generatedImageUrls,
    List<String>? generatedImagePaths,
    List<String>? inputImageBase64s,
    List<String>? generatedImageBase64s,
    List<String>? prompts,
  }) {
    return ProjectModel(
      id: id,
      userId: userId,
      timestamp: timestamp,
      inputImagePaths: inputImagePaths,
      generatedImagePaths: generatedImagePaths ?? this.generatedImagePaths,
      inputImageBase64s: inputImageBase64s ?? this.inputImageBase64s,
      generatedImageBase64s: generatedImageBase64s ?? this.generatedImageBase64s,
      inputImageUrls: inputImageUrls ?? this.inputImageUrls,
      generatedImageUrls: generatedImageUrls ?? this.generatedImageUrls,
      prompts: prompts ?? this.prompts,
    );
  }
}
