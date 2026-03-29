import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CloudStorageService {
  static final CloudStorageService _instance = CloudStorageService._internal();
  factory CloudStorageService() => _instance;
  CloudStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an input image (XFile) to Firebase Storage.
  /// Returns the download URL.
  Future<String> uploadInputImage({
    required String uid,
    required String projectId,
    required XFile imageFile,
    required int index,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final ref = _storage.ref().child(
        'users/$uid/projects/$projectId/inputs/input_$index.jpg',
      );

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(bytes, metadata);

      final url = await ref.getDownloadURL();
      debugPrint('Uploaded input image $index: $url');
      return url;
    } catch (e) {
      debugPrint('Upload input image error: $e');
      rethrow;
    }
  }

  /// Uploads a generated image (bytes) to Firebase Storage.
  /// Returns the download URL.
  Future<String> uploadGeneratedImage({
    required String uid,
    required String projectId,
    required Uint8List imageBytes,
    required int index,
  }) async {
    try {
      final ref = _storage.ref().child(
        'users/$uid/projects/$projectId/generated/gen_$index.jpg',
      );

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(imageBytes, metadata);

      final url = await ref.getDownloadURL();
      debugPrint('Uploaded generated image $index: $url');
      return url;
    } catch (e) {
      debugPrint('Upload generated image error: $e');
      rethrow;
    }
  }

  /// Deletes all files for a project from Firebase Storage.
  Future<void> deleteProjectFiles({
    required String uid,
    required String projectId,
  }) async {
    try {
      final ref = _storage.ref().child('users/$uid/projects/$projectId');

      // List and delete all files in inputs/
      try {
        final inputsRef = ref.child('inputs');
        final inputsList = await inputsRef.listAll();
        for (final item in inputsList.items) {
          await item.delete();
        }
      } catch (_) {
        // Folder may not exist
      }

      // List and delete all files in generated/
      try {
        final generatedRef = ref.child('generated');
        final generatedList = await generatedRef.listAll();
        for (final item in generatedList.items) {
          await item.delete();
        }
      } catch (_) {
        // Folder may not exist
      }

      debugPrint('Deleted all files for project $projectId');
    } catch (e) {
      debugPrint('Delete project files error: $e');
      // Don't rethrow - cleanup failure shouldn't block project deletion
    }
  }
}
