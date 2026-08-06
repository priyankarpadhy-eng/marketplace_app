import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market_app/models/omdb_item.dart';
import 'package:market_app/services/omdb_service.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:market_app/screens/omdb_grid_screen.dart';

class OmdbCarousel extends StatefulWidget {
  const OmdbCarousel({super.key});

  @override
  State<OmdbCarousel> createState() => _OmdbCarouselState();
}

class _OmdbCarouselState extends State<OmdbCarousel> {
  final OMDbService _omdbService = OMDbService();
  bool _isLoading = true;
  String? _errorMessage;
  List<OMDbItem> _items = [];

  final List<String> _movieTerms = ['Batman', 'Avengers', 'Star Wars', 'Inception', 'Matrix', 'Harry Potter'];
  final List<String> _tvTerms = ['Breaking Bad', 'Game of Thrones', 'Stranger Things', 'The Office', 'Friends', 'Sopranos'];

  @override
  void initState() {
    super.initState();
    _fetchCarouselData();
  }

  Future<void> _fetchCarouselData() async {
    try {
      List<OMDbItem> fetched = [];
      
      // Fetch movies
      for (final term in _movieTerms) {
        final results = await _omdbService.search(term, type: 'movie');
        if (results.isNotEmpty) {
          for (final item in results.take(3)) {
            final details = await _omdbService.getByImdbId(item.imdbId);
            if (details != null && details.imdbRating != null && details.imdbRating != 'N/A') {
              fetched.add(details);
            }
          }
        }
      }

      // Fetch tv shows
      for (final term in _tvTerms) {
        final results = await _omdbService.search(term, type: 'series');
        if (results.isNotEmpty) {
          for (final item in results.take(3)) {
            final details = await _omdbService.getByImdbId(item.imdbId);
            if (details != null && details.imdbRating != null && details.imdbRating != 'N/A') {
              fetched.add(details);
            }
          }
        }
      }

      // Sort by rating descending
      fetched.sort((a, b) {
        final ratingA = double.tryParse(a.imdbRating ?? '0') ?? 0.0;
        final ratingB = double.tryParse(b.imdbRating ?? '0') ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      if (mounted) {
        setState(() {
          _items = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load curated feed.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      // Return shrink to avoid "double loading" visuals. 
      // It will just show the main feed, and pop in once the movies are loaded.
      return const SizedBox.shrink();
    }

    if (_errorMessage != null || _items.isEmpty) {
      return const SizedBox.shrink(); 
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Curated for you",
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.02,
                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OmdbGridScreen()),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      "View all",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return _buildCarouselCard(item, isDark);
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCarouselCard(OMDbItem item, bool isDark) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: (item.poster != null && item.poster!.isNotEmpty)
                        ? Image.network(
                            item.poster!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
                if (item.imdbRating != null && item.imdbRating != 'N/A')
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            item.imdbRating!,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${item.year} • ${item.type.toUpperCase()}",
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.movie_creation_outlined, size: 32, color: Colors.grey),
    );
  }
}
