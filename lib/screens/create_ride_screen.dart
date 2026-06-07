import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slide_to_act/slide_to_act.dart' as slide_to_act;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/app_user.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'ride_detail_screen.dart';

class CreateRideScreen extends StatefulWidget {
  final AppUser currentUser;

  const CreateRideScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  
  TextEditingController? _fromFieldController;
  TextEditingController? _toFieldController;
  final _phoneController = TextEditingController();

  DateTime? _departure;
  String _genderPreference = 'mixed';
  int _seats = 4;
  
  final List<String> _allPlaces = [
    'Aryabhatta Bhawan',
    'Brahmos Bhawan',
    'Surya Bhawan',
    'Bhasker Bhawan',
    'Akash Bhawan',
    'Rohini Bhawan',
    'Prithwi Bhawan',
    'Talcher Road',
    'Talcher Thermal',
    'Talcher Station',
    'Angul Bus Stand',
    'Angul Station',
    'Banarpal',
  ];

  bool _submitting = false;
  final RideService _rideService = RideService();

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.currentUser.phoneNumber;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showResponsibilityDialog();
    });
  }

  void _showResponsibilityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text("Organizer Note", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "As the ride creator, the responsibility of contacting the auto-rickshaw/rickshaw is yours. IGIT Marketplace is just a platform to connect users and split costs.",
          style: GoogleFonts.outfit(fontSize: 15, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _pickDeparture() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    setState(() {
      _departure = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<Map<String, dynamic>?> _showPhoneRequestDialog() async {
    final phoneController = TextEditingController(text: widget.currentUser.phoneNumber);
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Confirm Contact Number", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Please confirm your phone number so fellow riders can contact you for the ride. You can update it here if needed."),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                hintText: "Enter your 10-digit number",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (phoneController.text.trim().length == 10) {
                Navigator.pop(context, phoneController.text.trim());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit number')));
              }
            },
            child: const Text("Save & Continue", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      final updatedUser = widget.currentUser.copyWith(
        phoneNumber: result,
        phoneVerified: (result == widget.currentUser.phoneNumber && widget.currentUser.phoneVerified),
      );
      await AuthService.instance.updateUserProfile(updatedUser);
      return {
        'phoneNumber': result,
        'phoneVerified': updatedUser.phoneVerified,
      };
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final phoneData = await _showPhoneRequestDialog();
    if (phoneData == null) return; 

    if (_departure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select departure time')),
      );
      return;
    }
    if (_departure!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Departure time must be in the future')),
      );
      return;
    }
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final updatedOrganizer = widget.currentUser.copyWith(
        phoneNumber: _phoneController.text.trim(),
      );
      final newRide = await _rideService.createRide(
        organizer: updatedOrganizer,
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
        departureTime: _departure!,
        genderPreference: _genderPreference,
        totalSeats: _seats,
        customPhone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RideDetailScreen(
            ride: newRide,
            currentUser: updatedOrganizer,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create ride: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required List<String> options,
  }) {
    return DropdownButtonFormField<String>(
      value: controller.text.isEmpty ? null : controller.text,
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
      style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: isDark ? Colors.white60 : Colors.blue.shade900, fontWeight: FontWeight.w600, fontSize: 13),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blueAccent, width: 2)),
        prefixIcon: Icon(icon, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        isDense: true,
      ),
      items: options.map((String option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            controller.text = newValue;
          });
        }
      },
      validator: (value) => value == null || value.trim().isEmpty ? 'Please select $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Host a Ride', 
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900, 
            color: Colors.white, 
            fontSize: 20,
            letterSpacing: 0.5,
          )
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFF2563EB), const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Main Form Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Locations
                        _buildTextField(
                          controller: _fromController,
                          label: 'Pickup Location',
                          icon: Icons.my_location,
                          isDark: isDark,
                          options: _allPlaces,
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 2,
                                height: 16,
                                color: Colors.blue.withOpacity(0.3),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  if (_fromController.text.isNotEmpty || _toController.text.isNotEmpty) {
                                    setState(() {
                                      final temp = _fromController.text;
                                      _fromController.text = _toController.text;
                                      _toController.text = temp;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.swap_vert_rounded, color: Colors.blue.shade500, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildTextField(
                          controller: _toController,
                          label: 'Drop-off Location',
                          icon: Icons.location_on,
                          isDark: isDark,
                          options: _allPlaces,
                        ),

                        const SizedBox(height: 16),
                        
                        // Departure Time
                        Text(
                          'DEPARTURE',
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 1.5
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDeparture,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.08) : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.transparent : Colors.blue.shade100),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.calendar_month_rounded, color: Colors.blueAccent, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _departure == null ? 'Select Date & Time' : DateFormat('EEEE, MMM dd').format(_departure!),
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 14,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      if (_departure != null)
                                        Text(
                                          DateFormat('hh:mm a').format(_departure!),
                                          style: GoogleFonts.outfit(
                                            color: isDark ? Colors.white70 : Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black54, size: 20),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Gender Preference
                        Text(
                          'GENDER PREFERENCE',
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 1.5
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildGenderChip('Mixed', 'mixed', Icons.group_rounded, isDark),
                            const SizedBox(width: 8),
                            _buildGenderChip('Female', 'female', Icons.female_rounded, isDark),
                            const SizedBox(width: 8),
                            _buildGenderChip('Male', 'male', Icons.male_rounded, isDark),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Seats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AVAILABLE SEATS',
                                  style: GoogleFonts.outfit(
                                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, 
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w900, 
                                    letterSpacing: 1.5
                                  ),
                                ),
                                Text(
                                  "(Includes yourself)",
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_seats',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: Colors.blueAccent,
                            inactiveTrackColor: isDark ? Colors.white10 : Colors.blue.shade100,
                            thumbColor: Colors.white,
                            overlayColor: Colors.blueAccent.withOpacity(0.2),
                            trackHeight: 4,
                            valueIndicatorColor: Colors.blueAccent,
                            valueIndicatorTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                          child: Slider(
                            min: 1,
                            max: 6,
                            divisions: 5,
                            value: _seats.toDouble(),
                            label: '$_seats Seats',
                            onChanged: (value) {
                              setState(() {
                                _seats = value.round();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Warning banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.amber.withOpacity(0.1) : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Safety first! Please contact your fellow riders once they join to coordinate the trip.",
                            style: GoogleFonts.outfit(
                              fontSize: 11, 
                              color: isDark ? Colors.amber.shade200 : Colors.orange.shade900, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Phone Number Input
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.blue.withOpacity(0.2)),
                    ),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Confirm Your Phone Number",
                        labelStyle: GoogleFonts.outfit(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                        prefixIcon: const Icon(Icons.phone_android_rounded, color: Colors.blue, size: 20),
                        border: InputBorder.none,
                        hintText: "Enter contact number",
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                    ),
                  ),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _submitting
                      ? Center(child: CircularProgressIndicator(color: isDark ? Colors.white : Colors.blue.shade900))
                      : slide_to_act.SlideAction(
                          text: 'Slide to Host Ride',
                          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : Colors.blue.shade900),
                          innerColor: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                          outerColor: isDark ? Colors.white.withOpacity(0.1) : Colors.blue.shade50,
                          sliderButtonIcon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                          elevation: 0,
                          borderRadius: 16,
                          sliderButtonIconPadding: 8,
                          onSubmit: () async {
                            if (_formKey.currentState!.validate()) {
                               await _submit();
                            }
                            return null;
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderChip(String label, String value, IconData icon, bool isDark) {
    final isSelected = _genderPreference == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _genderPreference = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected 
              ? Colors.blueAccent 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : (isDark ? Colors.white10 : Colors.grey.shade300),
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ] : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade600),
                size: 16,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
