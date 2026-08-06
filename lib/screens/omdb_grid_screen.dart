import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market_app/models/omdb_item.dart';
import 'package:market_app/services/omdb_service.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:market_app/widgets/app_loader.dart';

class OmdbGridScreen extends StatefulWidget {
  const OmdbGridScreen({super.key});

  @override
  State<OmdbGridScreen> createState() => _OmdbGridScreenState();
}

class _OmdbGridScreenState extends State<OmdbGridScreen> {
  final OMDbService _omdbService = OMDbService();
  bool _isLoading = true;
  String? _errorMessage;
  List<OMDbItem> _items = [];

  final List<String> _movieTerms = ['Batman', 'Avengers', 'Star Wars', 'Inception', 'Matrix', 'Harry Potter', 'Lord of the Rings', 'Spiderman', 'Jurassic Park', 'Mission Impossible'];
  final List<String> _tvTerms = ['Breaking Bad', 'Game of Thrones', 'Stranger Things', 'The Office', 'Friends', 'Sopranos', 'The Wire', 'Sherlock', 'Narcos', 'Succession'];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    try {
      List<OMDbItem> fetched = [];
      
      // Fetch movies
      for (final term in _movieTerms) {
        final results = await _omdbService.search(term, type: 'movie');
        if (results.isNotEmpty) {
          for (final item in results.take(4)) {
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
          for (final item in results.take(4)) {
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
          _errorMessage = "Failed to load expansive feed.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleStyle = GoogleFonts.syne(
      fontWeight: FontWeight.w700,
      fontSize: 20,
      letterSpacing: -0.02,
      color: isDark ? Colors.white : const Color(0xFF1E1B4B),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111111) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("All Curated Media", style: titleStyle),
        centerTitle: true,
      ),
      body: _isLoading
          ? const AppLoader(message: "Loading expansive catalog...")
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _buildGridCard(item, isDark);
                  },
                ),
    );
  }

  Widget _buildGridCard(OMDbItem item, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
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
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.movie_creation_outlined, size: 32, color: Colors.grey),
    );
  }
}
