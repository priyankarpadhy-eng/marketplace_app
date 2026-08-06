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
  late bool _isEditingPhone;
  final RideService _rideService = RideService();

  @override
  void initState() {
    super.initState();
    _isEditingPhone = widget.currentUser.phoneNumber.isEmpty || !widget.currentUser.phoneVerified;
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
            Icon(Icons.info_outline_rounded, color: AppTheme.rideAccent),
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
                backgroundColor: AppTheme.rideAccent,
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
            colorScheme: ColorScheme.light(
              primary: AppTheme.rideAccent,
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
            colorScheme: ColorScheme.light(
              primary: AppTheme.rideAccent,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isEditingPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save your phone number first')),
      );
      return;
    }

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
        phoneVerified: (_phoneController.text.trim() == widget.currentUser.phoneNumber && widget.currentUser.phoneVerified),
      );
      await AuthService.instance.updateUserProfile(updatedOrganizer);
      
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
      dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.rideAccent),
      style: GoogleFonts.outfit(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: isDark ? AppTheme.darkTextSecondary : AppTheme.rideAccent, fontWeight: FontWeight.w600, fontSize: 13),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt.withOpacity(0.5) : AppTheme.lightSurfaceAlt.withOpacity(0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.rideAccent.withOpacity(0.3), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.rideAccent, width: 2)),
        prefixIcon: Icon(icon, color: AppTheme.rideAccent, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final surfaceColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Host a Ride', 
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700, 
            color: textPrimary,
            fontSize: 20,
          )
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: [
            // Main Form
            Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route Section
                    _buildSectionHeader('ROUTE', Icons.route_rounded, isDark),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _fromController,
                      label: 'Pickup Location',
                      icon: Icons.my_location,
                      isDark: isDark,
                      options: _allPlaces,
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 2,
                            height: 20,
                            color: AppTheme.rideAccent.withOpacity(0.3),
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.rideAccent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.swap_vert_rounded, color: AppTheme.rideAccent, size: 18),
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

                    const SizedBox(height: 24),
                    
                    // Departure Time
                    _buildSectionHeader('DEPARTURE', Icons.schedule_rounded, isDark),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDeparture,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurfaceAlt.withOpacity(0.5) : AppTheme.lightSurfaceAlt.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.rideAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calendar_month_rounded, color: AppTheme.rideAccent, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _departure == null ? 'Select Date & Time' : DateFormat('EEEE, MMM dd').format(_departure!),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600, 
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                  ),
                                  if (_departure != null)
                                    Text(
                                      DateFormat('hh:mm a').format(_departure!),
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.rideAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Gender Preference
                    _buildSectionHeader('GENDER PREFERENCE', Icons.people_rounded, isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildGenderChip('Mixed', 'mixed', Icons.group_rounded, isDark),
                        const SizedBox(width: 10),
                        _buildGenderChip('Female', 'female', Icons.female_rounded, isDark),
                        const SizedBox(width: 10),
                        _buildGenderChip('Male', 'male', Icons.male_rounded, isDark),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Seats
                    _buildSectionHeader('AVAILABLE SEATS', Icons.event_seat_rounded, isDark),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "(Includes yourself)",
                          style: TextStyle(fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.rideAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.rideAccent.withOpacity(0.2)),
                          ),
                          child: Text(
                            '$_seats',
                            style: GoogleFonts.outfit(color: AppTheme.rideAccent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.rideAccent,
                        inactiveTrackColor: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                        thumbColor: AppTheme.rideAccent,
                        overlayColor: AppTheme.rideAccent.withOpacity(0.15),
                        trackHeight: 5,
                        valueIndicatorColor: AppTheme.rideAccent,
                        valueIndicatorTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
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
                    
                    const SizedBox(height: 24),

                    // Phone Number
                    _buildSectionHeader('CONTACT NUMBER', Icons.phone_rounded, isDark),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      readOnly: !_isEditingPhone,
                      style: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurfaceAlt.withOpacity(0.5) : AppTheme.lightSurfaceAlt.withOpacity(0.8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.rideAccent.withOpacity(0.3), width: 1.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.rideAccent, width: 2)),
                        prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.rideAccent, size: 20),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: TextButton(
                            onPressed: () {
                              if (_isEditingPhone) {
                                if (_phoneController.text.trim().length == 10) {
                                  setState(() {
                                    _isEditingPhone = false;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit number')));
                                }
                              } else {
                                setState(() {
                                  _isEditingPhone = true;
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: _isEditingPhone ? AppTheme.rideAccent : Colors.transparent,
                            ),
                            child: Text(
                              _isEditingPhone ? 'Save' : 'Edit',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: _isEditingPhone ? Colors.white : AppTheme.rideAccent),
                            ),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        isDense: true,
                      ),
                      validator: (v) => (v == null || v.isEmpty || v.length != 10) ? "Valid 10-digit number required" : null,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Safety notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.rideAccent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.rideAccent.withOpacity(0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.rideAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.shield_rounded, color: AppTheme.rideAccent, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Safety first! Please contact your fellow riders once they join to coordinate the trip.",
                      style: GoogleFonts.outfit(
                        fontSize: 12, 
                        color: textSecondary, 
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: _submitting
                ? Center(child: CircularProgressIndicator(color: AppTheme.rideAccent))
                : slide_to_act.SlideAction(
                    text: 'SLIDE TO HOST RIDE',
                    textStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: textSecondary.withOpacity(0.6),
                      letterSpacing: 1.5,
                    ),
                    innerColor: AppTheme.rideAccent,
                    outerColor: AppTheme.rideAccent.withOpacity(0.1),
                    sliderButtonIcon: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                    elevation: 0,
                    borderRadius: 16,
                    sliderButtonIconPadding: 12,
                    sliderRotate: false,
                    submittedIcon: Icon(Icons.check_rounded, color: Colors.white, size: 24),
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
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.rideAccent),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: AppTheme.rideAccent, 
            fontSize: 10, 
            fontWeight: FontWeight.w800, 
            letterSpacing: 1.2
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip(String label, String value, IconData icon, bool isDark) {
    final isSelected = _genderPreference == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _genderPreference = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
              ? AppTheme.rideAccent 
              : (isDark ? AppTheme.darkSurfaceAlt.withOpacity(0.5) : AppTheme.lightSurfaceAlt.withOpacity(0.8)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.rideAccent : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                color: isSelected ? Colors.white : textSecondary(isDark),
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color textSecondary(bool isDark) => isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
}
