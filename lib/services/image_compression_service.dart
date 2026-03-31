import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressionService {
  /// Compress for Gemini API calls.
  /// Target: 1024px longest edge, 80% JPEG quality (~200-500KB).
  /// Gemini downscales internally, so full resolution is wasted cost.
  static Future<Uint8List> compressForApi(Uint8List imageBytes) async {
    final originalSize = imageBytes.length;

    final result = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 1024,
      minHeight: 1024,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    debugPrint(
      'Image compressed for API: ${_formatBytes(originalSize)} → ${_formatBytes(result.length)}',
    );
    return result;
  }

  /// Compress for Firebase Storage uploads.
  /// Target: 2048px longest edge, 85% JPEG quality (~500KB-1MB).
  /// Higher quality than API since users may download these.
  static Future<Uint8List> compressForStorage(Uint8List imageBytes) async {
    final originalSize = imageBytes.length;

    final result = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 2048,
      minHeight: 2048,
      quality: 85,
      format: CompressFormat.jpeg,
    );

    debugPrint(
      'Image compressed for Storage: ${_formatBytes(originalSize)} → ${_formatBytes(result.length)}',
    );
    return result;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
