import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/media_service.dart';
import '../screens/bin/media_preview_screen.dart';

class MediaPickerWidget extends StatelessWidget {
  final Function(MediaAttachment, String? caption) onMediaSelected;
  final Map<String, dynamic>? replyToMessage;
  final String? binId;
  final String? replyToMessageId;
  final Function(MediaAttachment, String?)? onSendDirectly;

  const MediaPickerWidget({
    super.key,
    required this.onMediaSelected,
    this.replyToMessage,
    this.binId,
    this.replyToMessageId,
    this.onSendDirectly,
  });

  Future<void> _pickImage(ImageSource source, NavigatorState navigator) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final size = await file.length();

      final media = MediaAttachment(
        type: MediaType.image,
        file: file,
        size: size,
      );

      // Navigate to preview screen
      final result = await navigator.push(
        MaterialPageRoute(
          builder: (context) => MediaPreviewScreen(
            media: media,
            binId: binId ?? '',
            replyToMessage: replyToMessage,
            replyToMessageId: replyToMessageId,
            onSend: onSendDirectly,
          ),
        ),
      );

      if (result != null) {
        onMediaSelected(
          result['media'] as MediaAttachment,
          result['caption'] as String?,
        );
      }
    }
  }

  void _showMediaPicker(BuildContext context) {
    // Store root navigator before showing bottom sheet
    final rootNavigator = Navigator.of(context, rootNavigator: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Media',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickImage(ImageSource.gallery, rootNavigator);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickImage(ImageSource.camera, rootNavigator);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: () => _showMediaPicker(context),
      tooltip: 'Attach Media',
    );
  }
}

