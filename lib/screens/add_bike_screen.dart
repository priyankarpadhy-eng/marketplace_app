import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:market_app/theme/app_theme.dart';
import '../models/bike_rental_model.dart';
import '../services/bike_rental_service.dart';
import '../models/app_user.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';

class AddBikeScreen extends StatefulWidget {
  final AppUser currentUser;
  final BikeListing? editBike;

  const AddBikeScreen({super.key, required this.currentUser, this.editBike});

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  final BikeRentalService _bikeService = BikeRentalService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  
  String _title = '';
  String _description = '';
  double _pricePerHour = 0.0;
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, String> _specs = {'Engine': '150cc', 'Max Speed': '110km/h', 'Type': 'Sport'};
  Map<String, double> _customPrices = {};

  @override
  void initState() {
    super.initState();
    if (widget.editBike != null) {
      _title = widget.editBike!.title;
      _description = widget.editBike!.description;
      _pricePerHour = widget.editBike!.pricePerHour;
      _specs = Map<String, String>.from(widget.editBike!.specs);
      _customPrices = Map<String, double>.from(widget.editBike!.customPrices);
    }
  }

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

  void _showAddCustomPriceDialog() {
    final hoursController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Custom Price"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Duration (Hours)",
                hintText: "e.g. 2, 12, 24",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Total Price (₹)",
                hintText: "Price for this duration",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (hoursController.text.isNotEmpty && priceController.text.isNotEmpty) {
                setState(() {
                  _customPrices[hoursController.text] = double.parse(priceController.text);
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _saveBike() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && widget.editBike == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image.')));
      return;
    }

    setState(() => _isLoading = true);
    _formKey.currentState!.save();

    try {
      String imageUrl = widget.editBike?.images.isNotEmpty == true ? widget.editBike!.images.first : '';
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadFile(_selectedImage!, folder: 'rentals');
      }

      if (widget.editBike != null) {
        final updatedData = {
          'title': _title,
          'description': _description,
          'pricePerHour': _pricePerHour,
          'images': [imageUrl],
          'specs': _specs,
          'customPrices': _customPrices,
        };
        await _bikeService.updateBikeDetails(widget.editBike!.id, updatedData);
      } else {
        final bike = BikeListing(
          id: '',
          shopId: widget.currentUser.id,
          shopName: widget.currentUser.name,
          title: _title,
          description: _description,
          pricePerHour: _pricePerHour,
          images: [imageUrl],
          specs: _specs,
          customPrices: _customPrices,
          createdAt: DateTime.now(),
        );

        await _bikeService.addBike(bike);

        // Pushes broadcast notification: Need Bikes? bike name is available for price name
        await NotificationService.instance.broadcastNotification(
          title: 'Need Bikes? 🛵',
          body: '$_title is available for ₹${_pricePerHour.toStringAsFixed(0)}/hr',
          type: 'rental',
          relatedId: widget.currentUser.id,
          image: imageUrl.isNotEmpty ? imageUrl : null,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.editBike != null ? "Edit Bike Details" : "Add New Bike")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(labelText: "Bike Title", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Required" : null,
              onSaved: (v) => _title = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
              maxLines: 3,
              validator: (v) => v!.isEmpty ? "Required" : null,
              onSaved: (v) => _description = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _pricePerHour == 0.0 ? '' : _pricePerHour.toStringAsFixed(0),
              decoration: const InputDecoration(labelText: "Price Per Hour (₹)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? "Required" : null,
              onSaved: (v) => _pricePerHour = double.parse(v!),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _showImageSelectionOptions,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Upload Bike Image", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Custom Time Pricing (Optional)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.orange),
                  onPressed: _showAddCustomPriceDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_customPrices.isEmpty)
              const Text("No custom prices added. Default hourly rate applies.", style: TextStyle(color: Colors.grey, fontSize: 14))
            else
              ..._customPrices.entries.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text("${e.key} Hours"),
                  trailing: Text("₹${e.value.toStringAsFixed(2)}"),
                  leading: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => _customPrices.remove(e.key));
                    },
                  ),
                ),
              )),
            const SizedBox(height: 24),
            Text("Specifications", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ..._specs.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(e.key)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(
                    initialValue: e.value,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    onChanged: (v) => _specs[e.key] = v,
                  )),
                ],
              ),
            )),
            const SizedBox(height: 32),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBike,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.editBike != null ? "Save Changes" : "List Bike Now", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
