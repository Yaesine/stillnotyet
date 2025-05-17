// lib/services/image_service_wrapper.dart
// A wrapper that maintains the same API as the original ImageService
// but uses Cloudinary for storage

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloudinary_image_service.dart';

class ImageService {
  final CloudinaryImageService _cloudinaryService = CloudinaryImageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = Uuid();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    return _cloudinaryService.pickImageFromGallery();
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    return _cloudinaryService.pickImageFromCamera();
  }

  // Upload image - maintains the same API as the original
  Future<String?> uploadImage(File imageFile, String userId) async {
    return _cloudinaryService.uploadImage(imageFile, userId);
  }

  // Delete image - maintains the same API signature
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Get the current user ID
      // Note: In a real app, you'd get this from auth, but for compatibility
      // we're extracting it from the URL which has userId in the filename

      // Extract userId from URL or filename pattern
      String userId = _extractUserIdFromUrl(imageUrl);

      if (userId.isEmpty) {
        // If we can't extract userId, we might need to get it from somewhere else
        // For now, just log and continue with removal from Firestore collections
        print('Warning: Could not extract userId from URL, using fallback method');

        // Search all users to find which one has this URL
        QuerySnapshot query = await _firestore.collection('users')
            .where('imageUrls', arrayContains: imageUrl)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          userId = query.docs.first.id;
        } else {
          print('No user found with this image URL');
          return false;
        }
      }

      return await _cloudinaryService.deleteImage(imageUrl, userId);
    } catch (e) {
      print('Error in delete image wrapper: $e');
      return false;
    }
  }

  // Helper method to try extracting userId from URL
  // Example URL: https://res.cloudinary.com/cloudname/image/upload/v123/profile_images/user123_abcdef.jpg
  String _extractUserIdFromUrl(String url) {
    try {
      // Try to extract from filename pattern userId_uuid
      Uri uri = Uri.parse(url);
      String path = uri.path;

      // Get the filename
      String filename = path.split('/').last;

      // Remove extension
      filename = filename.split('.').first;

      // Pattern is typically userId_uuid
      if (filename.contains('_')) {
        return filename.split('_').first;
      }

      return '';
    } catch (e) {
      print('Error extracting userId from URL: $e');
      return '';
    }
  }
}