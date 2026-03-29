import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:universal_io/io.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String? imagePath;
  final String? base64Image;
  final Uint8List? imageBytes;
  final String? networkImageUrl;

  const FullScreenImageViewer({
    super.key,
    this.imagePath,
    this.base64Image,
    this.imageBytes,
    this.networkImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // 0. Network URL (cloud images)
    if (networkImageUrl != null) {
      return CachedNetworkImage(
        imageUrl: networkImageUrl!,
        fit: BoxFit.contain,
        placeholder: (_, _) => const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
        errorWidget: (_, _, _) => _errorWidget(),
      );
    }

    // 1. Direct bytes (highest priority if provided)
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _errorWidget(),
      );
    }

    // 2. Base64 (Web)
    if (base64Image != null) {
      try {
        final bytes = base64Decode(base64Image!);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _errorWidget(),
        );
      } catch (e) {
        return _errorWidget();
      }
    }

    // 3. File Path (Mobile)
    if (imagePath != null) {
      if (kIsWeb) {
        return Image.network(
          imagePath!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _errorWidget(),
        );
      }
      return Image.file(
        File(imagePath!),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _errorWidget(),
      );
    }

    return _errorWidget();
  }

  Widget _errorWidget() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image, color: Colors.white54, size: 64),
        SizedBox(height: 16),
        Text('Could not load image', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
}
