import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────── User Operations ────────────

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final userDoc = _usersCollection.doc(uid);
    final snapshot = await userDoc.get();

    if (snapshot.exists) {
      // Update last login
      await userDoc.update({
        'lastLoginAt': DateTime.now().toIso8601String(),
        'displayName': displayName,
        'photoUrl': photoUrl,
      });
    } else {
      // Create new user with starter tokens
      final user = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        tokenBalance: 10,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await userDoc.set(user.toJson());
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final snapshot = await _usersCollection.doc(uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromJson(snapshot.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  Future<void> updateTokenBalance(String uid, int newBalance) async {
    await _usersCollection.doc(uid).update({
      'tokenBalance': newBalance,
    });
  }

  /// Returns the current token balance for a user.
  Future<int> getTokenBalance(String uid) async {
    try {
      final snapshot = await _usersCollection.doc(uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!['tokenBalance'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching token balance: $e');
      return 0;
    }
  }

  /// Atomically deducts 1 token. Returns false if balance is 0.
  Future<bool> deductToken(String uid) async {
    try {
      final docRef = _usersCollection.doc(uid);
      return _db.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(docRef);
        final currentBalance =
            snapshot.data()?['tokenBalance'] as int? ?? 0;
        if (currentBalance <= 0) return false;
        transaction.update(docRef, {'tokenBalance': currentBalance - 1});
        return true;
      });
    } catch (e) {
      debugPrint('Error deducting token: $e');
      return false;
    }
  }

  // ──────────── Project Operations ────────────

  CollectionReference<Map<String, dynamic>> _projectsCollection(String uid) =>
      _usersCollection.doc(uid).collection('projects');

  /// Generates a unique Firestore document ID for a new project.
  String generateProjectId(String uid) {
    return _projectsCollection(uid).doc().id;
  }

  Future<ProjectModel> saveProject({
    required String uid,
    required String projectId,
    required List<String> prompts,
    required List<String> inputImageUrls,
    required List<String> generatedImageUrls,
  }) async {
    final docRef = _projectsCollection(uid).doc(projectId);

    final project = ProjectModel(
      id: projectId,
      userId: uid,
      timestamp: DateTime.now(),
      inputImagePaths: [],
      generatedImagePaths: [],
      inputImageUrls: inputImageUrls,
      generatedImageUrls: generatedImageUrls,
      prompts: prompts,
    );

    await docRef.set(project.toJson());
    debugPrint('Project saved to Firestore: ${docRef.id}');
    return project;
  }

  Future<void> addGeneratedImageUrl({
    required String uid,
    required String projectId,
    required String imageUrl,
  }) async {
    await _projectsCollection(uid).doc(projectId).update({
      'generatedImageUrls': FieldValue.arrayUnion([imageUrl]),
    });
    debugPrint('Added generated image URL to project $projectId');
  }

  Future<List<ProjectModel>> getProjects(String uid, {int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = _projectsCollection(uid)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ProjectModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      return [];
    }
  }

  Future<void> deleteProject(String uid, String projectId) async {
    try {
      await _projectsCollection(uid).doc(projectId).delete();
      debugPrint('Project deleted from Firestore: $projectId');
    } catch (e) {
      debugPrint('Error deleting project: $e');
      rethrow;
    }
  }
}
