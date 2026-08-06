import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import '../models/app_user.dart';
import '../models/post.dart';
import '../services/feed_service.dart';
import '../services/storage_service.dart';
import '../services/github_storage_service.dart';
import '../theme/app_theme.dart';
import '../services/permission_service.dart';

class CreatePostScreen extends StatefulWidget {
  final AppUser currentUser;

  const CreatePostScreen({super.key, required this.currentUser});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  
  final FeedService _feedService = FeedService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  
  List<File> _selectedImages = [];
  File? _selectedVideo;
  String _selectedTag = 'Discussion';
  bool _isPosting = false;
  double _uploadProgress = 0.0;

  late final List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = ['Discussion', 'Freelancing', 'Confession', 'Poetic', 'Help', 'Truth', 'Spill', 'Real', 'Opinion'];
    _selectedTag = 'Discussion';
  }

  Future<void> _pickImage() async {
    final granted = await PermissionService.requestGalleryPermission(context);
    if (!granted) return;

    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 90);
    if (images.isEmpty) return;

    List<File> validImages = [];
    for (var img in images) {
      final File imageFile = File(img.path);
      final int sizeInBytes = await imageFile.length();
      if (sizeInBytes <= 50 * 1024 * 1024) {
        validImages.add(imageFile);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image ${img.name} exceeds 50MB limit')),
        );
      }
    }

    if (validImages.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(validImages);
        // Cap at 10 images max
        if (_selectedImages.length > 10) {
          _selectedImages = _selectedImages.sublist(0, 10);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 10 images allowed')),
          );
        }
        _selectedVideo = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final granted = await PermissionService.requestGalleryPermission(context);
    if (!granted) return;

    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    final File videoFile = File(video.path);
    final int sizeInBytes = await videoFile.length();
    if (sizeInBytes > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video size exceeds 50MB limit')),
        );
      }
      return;
    }

    setState(() {
      _selectedVideo = videoFile;
      _selectedImages.clear();
    });
  }

  Future<void> _handlePost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty && _selectedVideo == null) return;

    setState(() {
      _isPosting = true;
      _uploadProgress = 0.0;
    });

    try {
      List<String> imageUrls = [];
      String? videoUrl;
      
      if (_selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          String url = await _storageService.uploadFile(_selectedImages[i], folder: 'posts');
          imageUrls.add(url);
          setState(() {
            _uploadProgress = (i + 1) / _selectedImages.length;
          });
        }
      } else if (_selectedVideo != null) {
        videoUrl = await _storageService.uploadFile(_selectedVideo!, folder: 'posts/videos');
        setState(() {
          _uploadProgress = 1.0;
        });
      }

      final post = Post(
        id: '',
        content: _contentController.text.trim(),
        authorName: _selectedTag == 'Confession' ? 'Anonymous Student' : widget.currentUser.name,
        authorNickname: _selectedTag == 'Confession' ? null : widget.currentUser.nickname,
        authorId: widget.currentUser.id,
        authorAvatar: _selectedTag == 'Confession' ? null : widget.currentUser.profileImage,
        createdAt: DateTime.now(),
        tag: _selectedTag.toLowerCase(),
        image: imageUrls.isNotEmpty ? imageUrls.first : null,
        images: imageUrls.isNotEmpty ? imageUrls : null,
        video: videoUrl,
        budget: _selectedTag == 'Freelancing' ? _budgetController.text.trim() : null,
        contact: _selectedTag == 'Freelancing' ? _contactController.text.trim() : null,
      );

      await _feedService.createPost(post);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'discussion': return Colors.blue;
      case 'freelancing': return Colors.green;
      case 'confession': return Colors.purple;
      case 'poetic': return Colors.teal;
      case 'help': return Colors.orange;
      case 'truth': return Colors.red;
      case 'events': return Colors.amber;
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getTagColor(_selectedTag);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Create Post", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isPosting ? null : _handlePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: _isPosting 
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      if (_uploadProgress > 0) ...[
                        const SizedBox(width: 8),
                        Text("${(_uploadProgress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ]
                    ],
                  )
                : const Text("Post", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        bottom: _isPosting && _uploadProgress > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.transparent,
                  color: activeColor,
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Tag Indicator
            Text(
              "SHARING AS:",
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tags.length,
                itemBuilder: (context, index) {
                  final tag = _tags[index];
                  final isSelected = _selectedTag == tag;
                  final color = _getTagColor(tag);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tag, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      onSelected: (v) => setState(() => _selectedTag = tag),
                      selectedColor: color.withOpacity(0.2),
                      backgroundColor: Colors.transparent,
                      labelStyle: TextStyle(color: isSelected ? color : Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: isSelected ? color : Colors.grey.withOpacity(0.2)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Content Input
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 4,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: _selectedTag == 'Confession' 
                    ? "Write your heartfelt confession..." 
                    : "What's the vibe?",
                hintStyle: GoogleFonts.outfit(color: Colors.grey.withOpacity(0.5)),
                border: InputBorder.none,
              ),
            ),
            
            const SizedBox(height: 16),

            // Extra Fields for Freelancing
            if (_selectedTag == 'Freelancing') ...[
               const Divider(),
               const SizedBox(height: 12),
               Row(
                 children: [
                   Expanded(
                     child: _buildExtraField(_budgetController, "Budget (₹)", Icons.payments_rounded),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: _buildExtraField(_contactController, "Contact / Tag", Icons.alternate_email_rounded),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
            ],

            // Previews
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImages[index], width: 120, height: 120, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black.withOpacity(0.6),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedVideo != null) ...[
              Stack(
                children: [
                   Container(
                     height: 200,
                     width: double.infinity,
                     decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(24),
                     ),
                     child: const Center(child: Icon(Icons.videocam_rounded, size: 50, color: Colors.grey)),
                   ),
                   Positioned(
                    right: 12,
                    top: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedVideo = null),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12, left: 12,
                    child: Text(p.basename(_selectedVideo!.path), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  )
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Add Media Buttons
            if (_selectedTag != 'Poetic' && _selectedTag != 'Confession' && _selectedImages.length < 10 && _selectedVideo == null)
              _buildAddMediaRow(),
              
            const SizedBox(height: 100), // Spacing
          ],
        ),
      ),
    );
  }

  Widget _buildExtraField(TextEditingController controller, String hint, IconData icon, {Color color = Colors.green}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, size: 16, color: color),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAddMediaRow() {
    return Row(
      children: [
        Expanded(child: _buildMediaAction(Icons.image_rounded, "Add Image", _pickImage)),
        const SizedBox(width: 12),
        Expanded(child: _buildMediaAction(Icons.videocam_rounded, "Add Video", _pickVideo)),
      ],
    );
  }

  Widget _buildMediaAction(IconData icon, String label, VoidCallback onTap, {Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: iconColor ?? Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
