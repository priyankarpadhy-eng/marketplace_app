import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/ride.dart';
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
  final _phoneController = TextEditingController();

  DateTime? _departure;
  String _genderPreference = 'mixed';
  int _seats = 3;
  bool _submitting = false;
  final RideService _rideService = RideService();

  final List<String> _allPlaces = [
    'Campus Main Gate',
    'Aryabhatta Bhawan',
    'Brahmos Bhawan',
    'Surya Bhawan',
    'Bhasker Bhawan',
    'Akash Bhawan',
    'Rohini Bhawan',
    'Prithwi Bhawan',
    'Talcher Station',
    'Talcher Road',
    'Talcher Thermal',
    'Angul Station',
    'Angul Bus Stand',
    'Banarpal Chowk',
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.currentUser.phoneNumber;
    // Default departure: today, next hour rounded
    final now = DateTime.now();
    _departure = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    if (_fromController.text.isEmpty && _toController.text.isEmpty) return;
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }

  Future<void> _pickDepartureDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: _departure ?? now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.rideAccent,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departure ?? now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.rideAccent,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime == null) return;

    setState(() {
      _departure = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _setDepartureShortcut(int dayOffset) {
    final now = DateTime.now();
    final targetDay = now.add(Duration(days: dayOffset));
    setState(() {
      final currentHour = _departure?.hour ?? now.hour + 1;
      final currentMinute = _departure?.minute ?? 0;
      _departure = DateTime(
        targetDay.year,
        targetDay.month,
        targetDay.day,
        currentHour,
        currentMinute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit contact phone number')),
      );
      return;
    }

    if (_fromController.text.trim() == _toController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup and Drop-off locations cannot be identical')),
      );
      return;
    }

    if (_departure == null || _departure!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Departure time must be set in the future')),
      );
      return;
    }

    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final updatedOrganizer = widget.currentUser.copyWith(
        phoneNumber: phone,
        phoneVerified: phone == widget.currentUser.phoneNumber && widget.currentUser.phoneVerified,
      );
      await AuthService.instance.updateUserProfile(updatedOrganizer);

      final Ride newRide = await _rideService.createRide(
        organizer: updatedOrganizer,
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
        departureTime: _departure!,
        genderPreference: _genderPreference,
        totalSeats: _seats,
        customPhone: phone,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride created! Split fare between $_seats seats.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RideDetailScreen(
            ride: newRide,
            currentUser: updatedOrganizer,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create ride: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);

    final now = DateTime.now();
    final isToday = _departure != null &&
        _departure!.year == now.year &&
        _departure!.month == now.month &&
        _departure!.day == now.day;
    final isTomorrow = _departure != null &&
        _departure!.year == now.add(const Duration(days: 1)).year &&
        _departure!.month == now.add(const Duration(days: 1)).month &&
        _departure!.day == now.add(const Duration(days: 1)).day;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Host a Ride',
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Route Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ROUTE DETAILS',
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.8),
                      ),
                      IconButton(
                        onPressed: _swapLocations,
                        icon: const Icon(Icons.swap_vert_rounded, size: 20),
                        color: AppTheme.rideAccent,
                        tooltip: 'Swap locations',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Origin Input
                  DropdownButtonFormField<String>(
                    value: _fromController.text.isNotEmpty ? _fromController.text : null,
                    decoration: InputDecoration(
                      labelText: 'Pickup Location',
                      labelStyle: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(Icons.trip_origin_rounded, color: Color(0xFF16A34A), size: 18),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                    ),
                    dropdownColor: cardBg,
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                    items: _allPlaces.map((place) => DropdownMenuItem(value: place, child: Text(place))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _fromController.text = val);
                    },
                    validator: (val) => val == null || val.isEmpty ? 'Select pickup location' : null,
                  ),

                  const SizedBox(height: 12),

                  // Destination Input
                  DropdownButtonFormField<String>(
                    value: _toController.text.isNotEmpty ? _toController.text : null,
                    decoration: InputDecoration(
                      labelText: 'Drop-off Location',
                      labelStyle: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFFEA580C), size: 18),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                    ),
                    dropdownColor: cardBg,
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                    items: _allPlaces.map((place) => DropdownMenuItem(value: place, child: Text(place))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _toController.text = val);
                    },
                    validator: (val) => val == null || val.isEmpty ? 'Select drop-off location' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Schedule Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'DEPARTURE SCHEDULE',
                          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChoiceChip(
                            label: const Text('Today'),
                            labelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: isToday ? Colors.white : textPrimary),
                            selected: isToday,
                            selectedColor: AppTheme.rideAccent,
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onSelected: (_) => _setDepartureShortcut(0),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Tomorrow'),
                            labelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: isTomorrow ? Colors.white : textPrimary),
                            selected: isTomorrow,
                            selectedColor: AppTheme.rideAccent,
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onSelected: (_) => _setDepartureShortcut(1),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _pickDepartureDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.rideAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.schedule_rounded, color: AppTheme.rideAccent, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _departure != null ? DateFormat('EEEE, MMM d · yyyy').format(_departure!) : 'Select Date & Time',
                                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _departure != null ? 'Departure: ${DateFormat('h:mm a').format(_departure!)}' : 'Tap to pick exact departure time',
                                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.rideAccent, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_calendar_rounded, size: 18, color: textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ride Settings (Seats + Gender Filter)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAPACITY & PREFERENCES',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 14),

                  // Seats Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Available Seats',
                          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            color: textPrimary,
                            visualDensity: VisualDensity.compact,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.rideAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_seats',
                              style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.rideAccent),
                            ),
                          ),
                          IconButton(
                            onPressed: _seats < 6 ? () => setState(() => _seats++) : null,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: textPrimary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Gender Preference
                  Text(
                    'Who can join this ride?',
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildGenderSegment('Mixed', 'mixed', Icons.group_outlined, isDark),
                      const SizedBox(width: 8),
                      _buildGenderSegment('Female Only', 'female', Icons.female_rounded, isDark),
                      const SizedBox(width: 8),
                      _buildGenderSegment('Male Only', 'male', Icons.male_rounded, isDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact Phone Number Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COORDINATION CONTACT',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Contact Phone Number',
                      labelStyle: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rideAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      'Publish Ride Offer',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSegment(String label, String value, IconData icon, bool isDark) {
    final isSelected = _genderPreference == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _genderPreference = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.rideAccent : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
