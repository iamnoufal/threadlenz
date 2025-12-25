import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class ImageUploadCard extends StatelessWidget {
  final XFile? imageFile;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final String label;

  const ImageUploadCard({
    super.key,
    required this.imageFile,
    required this.onTap,
    this.onRemove,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1, // Square
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kIsWeb
                          ? Image.network(imageFile!.path, fit: BoxFit.cover)
                          : Image.file(
                              File(imageFile!.path),
                              fit: BoxFit.cover,
                            ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.softGrey, width: 2),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: AppTheme.emeraldPrimary.withOpacity(0.5),
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              label,
                              style: TextStyle(
                                color: AppTheme.emeraldPrimary.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (imageFile != null && onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }
}
