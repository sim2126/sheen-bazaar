import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A tappable image field that shows a preview (local file or network URL)
/// with a camera-icon overlay. Calls [onPick] with the chosen [XFile].
class ImagePickerField extends StatelessWidget {
  final String label;
  final XFile? pickedFile;
  final String existingUrl;
  final double aspectRatio;
  final void Function(XFile) onPick;

  const ImagePickerField({
    super.key,
    required this.label,
    required this.onPick,
    required this.existingUrl,
    this.pickedFile,
    this.aspectRatio = 1.0,
  });

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (file != null) onPick(file);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocal = pickedFile != null;
    final hasNetwork = existingUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D2B1F),
              letterSpacing: 0.3,
            ),
          ),
        ),
        GestureDetector(
          onTap: _pick,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3D2B1F)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasLocal)
                      Image.file(
                        File(pickedFile!.path),
                        fit: BoxFit.cover,
                      )
                    else if (hasNetwork)
                      Image.network(
                        existingUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholder(),
                      )
                    else
                      _placeholder(),
                    // Camera icon overlay
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D2B1F).withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _placeholder() {
    return const ColoredBox(
      color: Color(0xFFEDE0CC),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: Color(0xFF3D2B1F),
          ),
          SizedBox(height: 6),
          Text(
            'Tap to upload',
            style: TextStyle(
              color: Color(0xFF3D2B1F),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
