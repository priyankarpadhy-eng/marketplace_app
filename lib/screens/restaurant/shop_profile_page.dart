import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_user.dart';
import '../../services/food_service.dart';
import '../../services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RestaurantShopProfilePage extends StatefulWidget {
  final AppUser currentUser;
  const RestaurantShopProfilePage({super.key, required this.currentUser});

  @override
  State<RestaurantShopProfilePage> createState() => _RestaurantShopProfilePageState();
}

class _RestaurantShopProfilePageState extends State<RestaurantShopProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  List<String> _imageUrls = [];
  bool _isLoading = false;

  final FoodService _foodSvc = FoodService();
  final StorageService _storageSvc = StorageService();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentUser.shopName ?? '');
    _phoneCtrl = TextEditingController(text: widget.currentUser.phoneNumber);
    _addressCtrl = TextEditingController(text: widget.currentUser.shopAddress ?? '');
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _foodSvc.getShops().first;
      final shop = snapshot.firstWhere((s) => s.id == widget.currentUser.id);
      setState(() {
        _nameCtrl.text = shop.name;
        _phoneCtrl.text = shop.phoneNumber;
        _addressCtrl.text = shop.address;
        _imageUrls = List<String>.from(shop.images);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // It's fine if shop doc doesn't exist yet
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final url = await _storageSvc.uploadFile(File(pickedFile.path), folder: 'shop_images');
        setState(() {
          _imageUrls.add(url);
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _foodSvc.updateShopDetails(widget.currentUser.id, {
        'name': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'imageUrl': _imageUrls.isNotEmpty ? _imageUrls.first : '',
        'images': _imageUrls,
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Shop Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Basic Information', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField(_nameCtrl, 'Shop Name', Icons.store_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneCtrl, 'Contact Number', Icons.phone_rounded, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(_addressCtrl, 'Shop Address', Icons.location_on_rounded, maxLines: 2),
                  
                  const SizedBox(height: 32),
                  Text('Shop Images', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Add photos of your shop or food to attract customers', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                            ),
                            child: const Icon(Icons.add_a_photo_rounded, color: Colors.grey),
                          ),
                        ),
                        ..._imageUrls.map((url) => Stack(
                          children: [
                            Container(
                              width: 120,
                              margin: const EdgeInsets.only(left: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(image: CachedNetworkImageProvider(url), fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageUrls.remove(url)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'Please enter $label' : null,
    );
  }
}
