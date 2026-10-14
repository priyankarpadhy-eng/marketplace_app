import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_user.dart';
import '../models/marketplace_item.dart';
import '../services/marketplace_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';

class ListProductScreen extends StatefulWidget {
  final AppUser currentUser;
  final MarketplaceItem? editItem;

  const ListProductScreen({super.key, required this.currentUser, this.editItem});

  @override
  State<ListProductScreen> createState() => _ListProductScreenState();
}

class _ListProductScreenState extends State<ListProductScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _mobileController;
  late final TextEditingController _sellingReasonController;
  late final TextEditingController _buyingReasonController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editItem?.title ?? '');
    _priceController = TextEditingController(text: widget.editItem != null ? widget.editItem!.price.toStringAsFixed(0) : '');
    _descriptionController = TextEditingController(text: widget.editItem?.description ?? '');
    _locationController = TextEditingController(text: widget.editItem?.location ?? '');
    _mobileController = TextEditingController(text: widget.editItem?.mobileNumber ?? '');
    _sellingReasonController = TextEditingController(text: widget.editItem?.sellingReason ?? '');
    _buyingReasonController = TextEditingController(text: widget.editItem?.buyingReason ?? '');
    if (widget.editItem != null) {
      _selectedCategory = widget.editItem!.category;
      _selectedCondition = widget.editItem!.condition;
    }
  }

  final _formKey = GlobalKey<FormState>();

  final MarketplaceService _marketplaceService = MarketplaceService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  File? _proofImage;
  File? _productVideo;
  
  String _selectedCategory = 'Textbooks';
  String _selectedCondition = 'Good';
  bool _isLoading = false;

  final List<String> _categories = ['Textbooks', 'Electronics', 'Furniture', 'Clothing', 'Housing', 'Other'];
  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Refurbished'];

  Future<void> _showImageSelectionOptions() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: isDark ? Colors.white : Colors.black),
              title: Text('Gallery', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: isDark ? Colors.white : Colors.black),
              title: Text('Camera', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    bool granted = false;
    if (source == ImageSource.gallery) {
      granted = await PermissionService.requestGalleryPermission(context);
    } else {
      granted = await PermissionService.requestCameraPermission(context);
    }
    
    if (!granted) return;

    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Edit Image',
            toolbarColor: AppTheme.primary,
            toolbarWidgetColor: Colors.black,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]),
        IOSUiSettings(
          title: 'Edit Image',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() => _selectedImage = File(croppedFile.path));
    }
  }

  Future<void> _pickProofImage(ImageSource source) async {
    bool granted = false;
    if (source == ImageSource.gallery) {
      granted = await PermissionService.requestGalleryPermission(context);
    } else {
      granted = await PermissionService.requestCameraPermission(context);
    }
    
    if (!granted) return;

    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;
    
    setState(() => _proofImage = File(image.path));
  }

  Future<void> _pickVideo() async {
    bool granted = await PermissionService.requestGalleryPermission(context);
    if (!granted) return;

    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    final bytes = await File(video.path).length();
    if (bytes > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video must be under 50MB. Please choose a smaller file.')));
      }
      return;
    }

    setState(() => _productVideo = File(video.path));
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && widget.editItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image.')));
      return;
    }
    if (_proofImage == null && widget.editItem?.proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proof of Purchase/Receipt is required.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = widget.editItem?.image ?? '';
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadFile(_selectedImage!, folder: 'marketplace');
      }
      
      String proofUrl = widget.editItem?.proofImage ?? '';
      if (_proofImage != null) {
        proofUrl = await _storageService.uploadFile(_proofImage!, folder: 'marketplace/proofs');
      }

      String videoUrl = widget.editItem?.videoUrl ?? '';
      if (_productVideo != null) {
        videoUrl = await _storageService.uploadFile(_productVideo!, folder: 'marketplace/videos');
      }

      if (widget.editItem != null) {
        final updatedData = {
          'title': _titleController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'category': _selectedCategory,
          'description': _descriptionController.text.trim(),
          'sellingReason': _sellingReasonController.text.trim(),
          'buyingReason': _buyingReasonController.text.trim(),
          'image': imageUrl,
          'images': [imageUrl],
          'proofImage': proofUrl,
          'videoUrl': videoUrl.isNotEmpty ? videoUrl : null,
          'location': _locationController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
          'condition': _selectedCondition,
        };
        await _marketplaceService.updateListingDetails(widget.editItem!.id, updatedData);
      } else {
        final item = MarketplaceItem(
          id: '',
          title: _titleController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory,
          description: _descriptionController.text.trim(),
          sellingReason: _sellingReasonController.text.trim(),
          buyingReason: _buyingReasonController.text.trim(),
          image: imageUrl,
          images: [imageUrl],
          proofImage: proofUrl,
          videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
          sellerId: widget.currentUser.id,
          sellerName: widget.currentUser.name,
          location: _locationController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          condition: _selectedCondition,
          createdAt: DateTime.now(),
        );
        await _marketplaceService.createListing(item);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("List an Item", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              InkWell(
                onTap: _showImageSelectionOptions,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: isDark ? Colors.white54 : Colors.grey),
                            const SizedBox(height: 8),
                            Text("Upload Product Image", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _buildField("Title", _titleController, "e.g. Engineering Mathematics Vol 1"),
              _buildField("Price (₹)", _priceController, "e.g. 250", keyboardType: TextInputType.number),
              
              Text("Category", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              _buildDropdown(_categories, _selectedCategory, (v) => setState(() => _selectedCategory = v!)),
              const SizedBox(height: 16),

              Text("Condition", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              _buildDropdown(_conditions, _selectedCondition, (v) => setState(() => _selectedCondition = v!)),
              const SizedBox(height: 16),

              _buildField("Description", _descriptionController, "Tell us more about the item...", maxLines: 3),
              _buildField("Why are you selling it?", _sellingReasonController, "e.g. I upgraded to a new model", maxLines: 2),
              _buildField("Why should someone buy it?", _buyingReasonController, "e.g. Great condition and fast", maxLines: 2),
              _buildField("Location", _locationController, "e.g. Hostel 4 or Main Gate"),
              _buildField("Mobile Number", _mobileController, "e.g. 9876543210", keyboardType: TextInputType.phone),

              const SizedBox(height: 16),
              Text("Proof of Purchase", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: Icon(Icons.photo_library, color: isDark ? Colors.white : Colors.black),
                            title: Text('Gallery', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                            onTap: () {
                              Navigator.pop(context);
                              _pickProofImage(ImageSource.gallery);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.camera_alt, color: isDark ? Colors.white : Colors.black),
                            title: Text('Camera', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                            onTap: () {
                              Navigator.pop(context);
                              _pickProofImage(ImageSource.camera);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: _proofImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_proofImage!, fit: BoxFit.cover),
                        )
                      : widget.editItem?.proofImage != null && widget.editItem!.proofImage!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(widget.editItem!.proofImage!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 32, color: isDark ? Colors.white54 : Colors.grey),
                                const SizedBox(height: 8),
                                Text("Upload Receipt / Invoice / Proof", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),

              Text("Product Video (Optional)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickVideo,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: _productVideo != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 32, color: Colors.green),
                            const SizedBox(height: 8),
                            Text("Video Selected", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : widget.editItem?.videoUrl != null && widget.editItem!.videoUrl!.isNotEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.video_library_rounded, size: 32, color: Colors.blue),
                                const SizedBox(height: 8),
                                Text("Video Previously Uploaded", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_rounded, size: 32, color: isDark ? Colors.white54 : Colors.grey),
                                const SizedBox(height: 8),
                                Text("Upload Video (Max 50MB)", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Note: Uploading a video showing the product working significantly increases your chances of selling!",
                style: GoogleFonts.roboto(fontSize: 12, color: Colors.green),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A5AE0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.editItem != null ? "Save Changes" : "List Item Now", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType, int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          validator: (v) => v!.isEmpty ? "Required" : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdown(List<String> items, String value, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
