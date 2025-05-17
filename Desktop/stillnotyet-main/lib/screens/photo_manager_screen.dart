import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/image_service.dart';

class PhotoManagerScreen extends StatefulWidget {
  const PhotoManagerScreen({Key? key}) : super(key: key);

  @override
  _PhotoManagerScreenState createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends State<PhotoManagerScreen> {
  final ImageService _imageService = ImageService();
  bool _isUploading = false;
  bool _isLoading = true;
  List<String> _photos = [];
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<AppAuthProvider>(context, listen: false).currentUserId;
    _loadUserPhotos();
  }

  Future<void> _loadUserPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadCurrentUser();

      if (userProvider.currentUser != null) {
        setState(() {
          _photos = List.from(userProvider.currentUser!.imageUrls);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print('Error loading photos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading photos: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final imagePicker = ImagePicker();
      final XFile? pickedFile = await imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadPhoto(File(pickedFile.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadPhoto(File photoFile) async {
    if (_photos.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 9 photos')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadedUrl = await _imageService.uploadImage(photoFile, _userId);

      if (uploadedUrl != null) {
        setState(() {
          _photos.add(uploadedUrl);
        });

        // Update user profile with new photo
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.currentUser;

        if (user != null) {
          final updatedUser = user.copyWith(
            imageUrls: _photos,
          );

          await userProvider.updateUserProfile(updatedUser);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo added successfully')),
          );
        }
      }
    } catch (e) {
      print('Error uploading photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deletePhoto(int index) async {
    // Don't allow deleting if it's the last photo
    if (_photos.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must have at least one photo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final photoUrl = _photos[index];

      // Delete from Firebase Storage
      await _imageService.deleteImage(photoUrl);

      // Update local photos list
      setState(() {
        _photos.removeAt(index);
      });

      // Update user profile
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user != null) {
        final updatedUser = user.copyWith(
          imageUrls: _photos,
        );

        await userProvider.updateUserProfile(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete photo: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setProfilePhoto(int index) async {
    if (index == 0) {
      // Already the main photo
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Move the selected photo to the first position
      final selectedPhoto = _photos[index];
      _photos.removeAt(index);
      _photos.insert(0, selectedPhoto);

      // Update user profile
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user != null) {
        final updatedUser = user.copyWith(
          imageUrls: _photos,
        );

        await userProvider.updateUserProfile(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully')),
        );
      }
    } catch (e) {
      print('Error setting profile photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set profile photo: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Photos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading ?
      const Center(child: CircularProgressIndicator()) :
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Add up to 9 photos to show yourself off',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photos.length < 9 ? _photos.length + 1 : 9, // +1 for add button
              itemBuilder: (context, index) {
                // If this is the last position and we have less than 9 photos
                if (index == _photos.length && _photos.length < 9) {
                  return _buildAddPhotoItem();
                }

                // Show existing photos
                return _buildPhotoItem(_photos[index], index);
              },
            ),
          ),

          // Show uploading indicator if needed
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Uploading photo...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(String photoUrl, int index) {
    return Stack(
      children: [
        // Photo container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(photoUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _deletePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),

        // Primary photo indicator
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Primary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Make primary button for non-primary photos
        if (index > 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: GestureDetector(
              onTap: () => _setProfilePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddPhotoItem() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_photo_alternate,
            size: 32,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}