import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/app_user.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Marketplace';
  final List<String> _categories = ['Marketplace', 'Bike Rental', 'Food & Snacks', 'Services', 'Other'];
  
  final List<File> _localImages = [];
  final List<String> _uploadedUrls = [];
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.shopName ?? '';
      _phoneController.text = user.phoneNumber;
      _addressController.text = user.shopAddress ?? '';
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _localImages.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_localImages.isEmpty && _uploadedUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one shop image')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser!;
      
      // Upload images
      for (var file in _localImages) {
        final url = await _storageService.uploadFile(file, folder: 'shops/${currentUser.id}');
        _uploadedUrls.add(url);
      }

      final updatedUser = currentUser.copyWith(
        shopName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        shopAddress: _addressController.text.trim(),
        verificationStatus: 'pending',
        shopImages: _uploadedUrls,
        // Tag is handled by the user's "What do you want to sell?" choice
        // but officially assigned by Founder during approval.
        // We store the intent in a metadata field or just use shopName for now.
      );

      await AuthService.instance.updateUserProfile(updatedUser);
      await userProvider.refreshUser();
      
      // Also create separate verification collection linked to user
      await FirebaseFirestore.instance.collection('shop_verifications').doc(currentUser.id).set({
        'userId': currentUser.id,
        'shopName': _nameController.text.trim(),
        'shopAddress': _addressController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'sellerName': currentUser.name,
        'images': _uploadedUrls,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification request sent successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // If already pending
    if (user.verificationStatus == 'pending') {
      return _buildPendingUI(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Shop Verification", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 32),
              
              _buildTextField(
                controller: _nameController,
                label: "Shop Name",
                icon: Icons.store_outlined,
                isDark: isDark,
                validator: (v) => v!.isEmpty ? "Enter shop name" : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _phoneController,
                label: "Business Phone Number",
                icon: Icons.phone_outlined,
                isDark: isDark,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Enter phone number" : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _addressController,
                label: "Shop Address / Location",
                icon: Icons.location_on_outlined,
                isDark: isDark,
                maxLines: 2,
                validator: (v) => v!.isEmpty ? "Enter shop address" : null,
              ),
              const SizedBox(height: 16),
              
              _buildCategoryDropdown(isDark),
              const SizedBox(height: 32),
              
              Text(
                "Shop Images",
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                "Upload clear photos of your shop or items you sell",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              _buildImageGrid(isDark),
              const SizedBox(height: 48),
              
              _buildSubmitButton(isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "START SELLING",
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 1.2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Setup your shop profile",
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
        ),
        Text(
          "Verify your details to gain access to the Seller Console",
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        labelStyle: GoogleFonts.outfit(color: Colors.grey),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(border: InputBorder.none),
          items: _categories.map((c) => DropdownMenuItem(
            value: c,
            child: Text(c, style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black)),
          )).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
      ),
    );
  }

  Widget _buildImageGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _localImages.length + 1,
      itemBuilder: (context, index) {
        if (index == _localImages.length) {
          return GestureDetector(
            onTap: _pickImages,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3), style: BorderStyle.solid),
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: Colors.orange),
            ),
          );
        }
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_localImages[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _localImages.removeAt(index)),
                child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.orange.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text("SUBMIT FOR VERIFICATION", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildPendingUI(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_empty_rounded, size: 64, color: Colors.orange),
              ),
              const SizedBox(height: 32),
              Text(
                "Request Sent!",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                "Your shop verification is currently pending approval from the Founder. You'll be notified once approved.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("BACK TO PROFILE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
