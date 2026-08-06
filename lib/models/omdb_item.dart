class OMDbItem {
  final String title;
  final String year;
  final String? poster;
  final String imdbId;
  final String type;
  final String? imdbRating;
  final String? plot;
  final List<Map<String, String>>? ratings;

  OMDbItem({
    required this.title,
    required this.year,
    this.poster,
    required this.imdbId,
    required this.type,
    this.imdbRating,
    this.plot,
    this.ratings,
  });

  factory OMDbItem.fromJson(Map<String, dynamic> json) {
    return OMDbItem(
      title: json['Title'] ?? '',
      year: json['Year'] ?? '',
      poster: (json['Poster'] != null && json['Poster'] != 'N/A') ? json['Poster'] : null,
      imdbId: json['imdbID'] ?? '',
      type: json['Type'] ?? 'movie',
      imdbRating: json['imdbRating'],
      plot: json['Plot'],
      ratings: json['Ratings'] != null
          ? List<Map<String, String>>.from(
              (json['Ratings'] as List).map((r) => Map<String, String>.from(r)))
          : null,
    );
  }
}
