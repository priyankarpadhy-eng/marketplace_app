import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/ride.dart';

class RideShareCard extends StatelessWidget {
  final Ride ride;
  final bool showDeepLink;

  const RideShareCard({
    super.key,
    required this.ride,
    this.showDeepLink = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350, // Reduced width
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Reduced padding
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)], // Slightly darker, more premium indigo
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 28,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MARKETPLACE',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              if (ride.rideNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    'RIDE #${ride.rideNumber}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Route Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('FROM'),
                    Text(
                      ride.from,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(width: 2, height: 12, color: Colors.white24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildLabel('TO'),
                    Text(
                      ride.to,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          
          // Details Grid
          Row(
            children: [
              _buildDetailItem('DATE', DateFormat('d MMMM').format(ride.departureTime)),
              _buildDetailItem('TIME', DateFormat('hh:mm a').format(ride.departureTime)),
              _buildDetailItem('SEATS', '${ride.totalSeats - ride.seatsTaken} Free', color: const Color(0xFFFDE68A)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Gender Preference
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ride.genderPreference == 'mixed') ...[
                      const Icon(Icons.male, color: Colors.white, size: 14),
                      const Icon(Icons.female, color: Colors.white, size: 14),
                    ] else
                      Icon(ride.genderPreference == 'male' ? Icons.male : Icons.female, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      ride.genderPreference == 'mixed' ? 'ANY GENDER' : (ride.genderPreference == 'male' ? 'MALE ONLY' : 'FEMALE ONLY'),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Organizer Info - Compact
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white24,
                  child: Text(
                    ride.organizerName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.organizerName,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ride.organizerPhone,
                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Footer
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'GET IT ON PLAY STORE',
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (showDeepLink)
                  Text(
                    'marketapp://ride/${ride.id}',
                    style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 8,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: Colors.white54,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color color = Colors.white}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
