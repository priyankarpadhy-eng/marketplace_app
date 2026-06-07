import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_item.dart';
import '../services/events_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventsService _eventsService = EventsService();
  String _activeCategory = 'All';

  final Map<String, dynamic> _categoryColors = {
    'general': {'bg': const Color(0xFFEFF6FF), 'text': const Color(0xFF1D4ED8)},
    'workshop': {'bg': const Color(0xFFF0FDF4), 'text': const Color(0xFF15803D)},
    'hackathon': {'bg': const Color(0xFFFAF5FF), 'text': const Color(0xFF7C3AED)},
    'fest': {'bg': const Color(0xFFFDF2F8), 'text': const Color(0xFFBE185D)},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: StreamBuilder<List<EventItem>>(
        stream: _eventsService.watchEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text("No events scheduled."));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Events Hub",
                        style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text("Join workshops, fests, and campus activities.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _EventCard(event: events[index], colors: _categoryColors),
                  childCount: events.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventItem event;
  final Map<String, dynamic> colors;

  const _EventCard({required this.event, required this.colors});

  @override
  Widget build(BuildContext context) {
    final catColor = colors[event.category.toLowerCase()] ?? colors['general'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.bannerUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: event.bannerUrl!, 
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor['bg'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: TextStyle(color: catColor['text'], fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (event.isPinned) ...[
                      const SizedBox(width: 8),
                      const FaIcon(FontAwesomeIcons.solidStar, color: Colors.orange, size: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(event.caption, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(event.eventDate, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 14, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(event.location ?? "Campus", style: const TextStyle(fontSize: 12)),
                  ],
                ),
                if (event.registrationLink != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => launchUrl(Uri.parse(event.registrationLink!)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A5AE0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Register Now", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
