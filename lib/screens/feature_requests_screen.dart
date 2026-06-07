import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/feature_request.dart';
import '../services/feature_request_service.dart';
import '../models/app_user.dart';

class FeatureRequestsScreen extends StatefulWidget {
  final AppUser currentUser;

  const FeatureRequestsScreen({super.key, required this.currentUser});

  @override
  State<FeatureRequestsScreen> createState() => _FeatureRequestsScreenState();
}

class _FeatureRequestsScreenState extends State<FeatureRequestsScreen> {
  final FeatureRequestService _service = FeatureRequestService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: StreamBuilder<List<FeatureRequest>>(
        stream: _service.watchRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data ?? [];
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Feature Requests",
                        style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Help shape the future by suggesting and voting on ideas.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              if (requests.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text("No requests yet. Be the first!")),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _RequestCard(
                      request: requests[index],
                      userId: widget.currentUser.id,
                      onVote: () => _service.voteRequest(requests[index].id, widget.currentUser.id),
                    ),
                    childCount: requests.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("Suggest"),
        icon: const Icon(Icons.lightbulb),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final FeatureRequest request;
  final String userId;
  final VoidCallback onVote;

  const _RequestCard({required this.request, required this.userId, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final hasVoted = request.voterIds.contains(userId);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(request.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        request.status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(request.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onVote,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasVoted ? const Color(0xFF6A5AE0).withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasVoted ? const Color(0xFF6A5AE0) : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.thumbsUp,
                        size: 16,
                        color: hasVoted ? const Color(0xFF6A5AE0) : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.votes.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasVoted ? const Color(0xFF6A5AE0) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            request.description,
            style: const TextStyle(color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "by ${request.authorName}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                "Recently",
                style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'in-progress': return Colors.blue;
      default: return Colors.orange;
    }
  }
}
