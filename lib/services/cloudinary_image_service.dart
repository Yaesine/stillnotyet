// lib/services/cloudinary_image_service.dart
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = Uuid();

  // Your Cloudinary cloud name and upload preset (replace with your actual credentials)
  final cloudinary = CloudinaryPublic('do5u0hen5', 'stillapp');

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Upload image to Cloudinary
  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      // Check file size first (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image is too large. Maximum file size is 5MB.');
      }

      // Generate a unique file name
      String fileName = '${userId}_${_uuid.v4()}';

      print('Uploading image to Cloudinary...');

      // Upload to Cloudinary
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'profile_images',
          resourceType: CloudinaryResourceType.Image,
          tags: ['profile', userId],
        ),
      );

      // Get secure URL from response
      String downloadUrl = response.secureUrl;

      print('Image uploaded successfully. URL: $downloadUrl');

      // Update the user's profile to include this new image
      await _firestore.collection('users').doc(userId).update({
        'imageUrls': FieldValue.arrayUnion([downloadUrl]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  // Delete image from user's profile
  // Note: This doesn't actually delete from Cloudinary as that requires admin keys
  Future<bool> deleteImage(String imageUrl, String userId) async {
    try {
      print('Removing image URL from user profile: $imageUrl');

      // Update the user's profile to remove this image URL
      await _firestore.collection('users').doc(userId).update({
        'imageUrls': FieldValue.arrayRemove([imageUrl]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Image URL removed from user profile successfully');

      return true;
    } catch (e) {
      print('Error removing image from profile: $e');
      return false;
    }
  }

  // Additional method: Get public ID from Cloudinary URL (useful for future admin operations)
  String? getPublicIdFromUrl(String url) {
    try {
      // Cloudinary URL format: https://res.cloudinary.com/cloud-name/image/upload/v1234567890/folder/filename.ext
      Uri uri = Uri.parse(url);
      List<String> pathSegments = uri.pathSegments;

      // Find the upload segment index
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        return null;
      }

      // Extract everything after "upload" and "version" segments
      List<String> publicIdParts = pathSegments.sublist(uploadIndex + 2);
      String publicId = publicIdParts.join('/');

      // Remove file extension if present
      int dotIndex = publicId.lastIndexOf('.');
      if (dotIndex != -1) {
        publicId = publicId.substring(0, dotIndex);
      }

      return publicId;
    } catch (e) {
      print('Error extracting public ID: $e');
      return null;
    }
  }
}