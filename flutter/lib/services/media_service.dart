import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'supabase_service.dart';

enum MediaType { image, video, audio }

class MediaAttachment {
  final MediaType type;
  final File file;
  final String? thumbnailPath; // For videos
  final int? duration; // For video/audio in seconds
  final int size; // Size in bytes

  MediaAttachment({
    required this.type,
    required this.file,
    this.thumbnailPath,
    this.duration,
    required this.size,
  });
}

class MediaService {
  final SupabaseService _supabaseService = SupabaseService();
  SupabaseClient get _client => _supabaseService.client;

  // Upload media file to Supabase storage
  Future<Map<String, dynamic>> uploadChatMedia({
    required String binId,
    required MediaAttachment media,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = path.extension(media.file.path).replaceFirst('.', '');
    final fileName = '${media.type.name}_${binId}_${user.id}_$timestamp.${ext.isEmpty ? _getDefaultExtension(media.type) : ext}';

    // Determine bucket based on media type
    final bucket = _getBucketForMediaType(media.type);

    try {
      // Read file bytes
      final bytes = await media.file.readAsBytes();

      // Upload main file
      await _client.storage.from(bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: _getContentType(media.type, ext),
        ),
      );

      final mediaUrl = _client.storage.from(bucket).getPublicUrl(fileName);

    // Upload thumbnail for videos if provided
    String? thumbnailUrl;
    if (media.type == MediaType.video && media.thumbnailPath != null) {
      final thumbnailFile = File(media.thumbnailPath!);
      if (await thumbnailFile.exists()) {
        final thumbnailBytes = await thumbnailFile.readAsBytes();
        final thumbnailFileName = 'thumb_$fileName';
        await _client.storage.from(bucket).uploadBinary(
          thumbnailFileName,
          thumbnailBytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
        thumbnailUrl = _client.storage.from(bucket).getPublicUrl(thumbnailFileName);
      }
    }

      return {
        'media_type': media.type.name,
        'media_url': mediaUrl,
        'media_thumbnail_url': thumbnailUrl,
        'media_size': media.size,
        'media_duration': media.duration,
        'media_filename': path.basename(media.file.path),
      };
    } catch (e) {
      // Log the full error for debugging
      print('Media upload error: $e');
      print('Bucket: $bucket');
      print('FileName: $fileName');
      print('File size: ${media.size} bytes');
      
      // Provide more helpful error messages
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('bucket') || errorString.contains('not found')) {
        throw Exception(
          'Storage bucket "$bucket" not found. Please create it in Supabase Storage. '
          'Go to Storage > Create bucket > Name: "$bucket" > Public bucket',
        );
      } else if (errorString.contains('permission') || errorString.contains('403') || errorString.contains('forbidden')) {
        throw Exception(
          'Permission denied for bucket "$bucket". Please check:\n'
          '1. Bucket is set to PUBLIC in Supabase Storage settings\n'
          '2. Storage policies allow authenticated users to upload\n'
          '3. Go to Storage > Policies > Add policy for INSERT',
        );
      } else if (errorString.contains('413') || errorString.contains('too large')) {
        throw Exception(
          'File is too large. Maximum size for $bucket is limited. '
          'Try compressing the image or using a smaller file.',
        );
      } else {
        throw Exception('Failed to upload media to "$bucket": ${e.toString()}');
      }
    }
  }

  String _getBucketForMediaType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return 'chat-images';
      case MediaType.video:
        return 'chat-videos';
      case MediaType.audio:
        return 'chat-audio';
    }
  }

  String _getDefaultExtension(MediaType type) {
    switch (type) {
      case MediaType.image:
        return 'jpg';
      case MediaType.video:
        return 'mp4';
      case MediaType.audio:
        return 'm4a';
    }
  }

  String _getContentType(MediaType type, String ext) {
    switch (type) {
      case MediaType.image:
        return 'image/${ext.isEmpty ? 'jpeg' : ext}';
      case MediaType.video:
        return 'video/${ext.isEmpty ? 'mp4' : ext}';
      case MediaType.audio:
        return 'audio/${ext.isEmpty ? 'm4a' : ext}';
    }
  }

  // Get file size in bytes
  Future<int> getFileSize(File file) async {
    return await file.length();
  }
}

