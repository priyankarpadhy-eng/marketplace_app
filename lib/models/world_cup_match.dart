class WorldCupMatch {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final int homeScore;
  final int awayScore;
  final String homeScorers;
  final String awayScorers;
  final String group;
  final String matchday;
  final String localDate;
  final String stadiumId;
  final bool finished;
  final String timeElapsed;
  final String type;
  final String? homeTeamLabel;
  final String? awayTeamLabel;
  final String? homeTeamNameEn;
  final String? awayTeamNameEn;
  final String? homeTeamNameFa;
  final String? awayTeamNameFa;

  WorldCupMatch({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.homeScorers,
    required this.awayScorers,
    required this.group,
    required this.matchday,
    required this.localDate,
    required this.stadiumId,
    required this.finished,
    required this.timeElapsed,
    required this.type,
    this.homeTeamLabel,
    this.awayTeamLabel,
    this.homeTeamNameEn,
    this.awayTeamNameEn,
    this.homeTeamNameFa,
    this.awayTeamNameFa,
  });

  factory WorldCupMatch.fromJson(Map<String, dynamic> json) {
    int parseScore(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return WorldCupMatch(
      id: json['id']?.toString() ?? '',
      homeTeamId: json['home_team_id']?.toString() ?? '',
      awayTeamId: json['away_team_id']?.toString() ?? '',
      homeScore: parseScore(json['home_score']),
      awayScore: parseScore(json['away_score']),
      homeScorers: json['home_scorers']?.toString() ?? '',
      awayScorers: json['away_scorers']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
      matchday: json['matchday']?.toString() ?? '',
      localDate: json['local_date']?.toString() ?? '',
      stadiumId: json['stadium_id']?.toString() ?? '',
      finished: json['finished']?.toString().toUpperCase() == 'TRUE',
      timeElapsed: json['time_elapsed']?.toString() ?? 'notstarted',
      type: json['type']?.toString() ?? 'group',
      homeTeamLabel: json['home_team_label']?.toString(),
      awayTeamLabel: json['away_team_label']?.toString(),
      homeTeamNameEn: json['home_team_name_en']?.toString(),
      awayTeamNameEn: json['away_team_name_en']?.toString(),
      homeTeamNameFa: json['home_team_name_fa']?.toString(),
      awayTeamNameFa: json['away_team_name_fa']?.toString(),
    );
  }

  String get homeDisplayName {
    if (homeTeamNameEn != null && homeTeamNameEn!.isNotEmpty && homeTeamNameEn != 'null') {
      return homeTeamNameEn!;
    }
    if (homeTeamLabel != null && homeTeamLabel!.isNotEmpty && homeTeamLabel != 'null') {
      return homeTeamLabel!;
    }
    return 'TBD';
  }

  String get awayDisplayName {
    if (awayTeamNameEn != null && awayTeamNameEn!.isNotEmpty && awayTeamNameEn != 'null') {
      return awayTeamNameEn!;
    }
    if (awayTeamLabel != null && awayTeamLabel!.isNotEmpty && awayTeamLabel != 'null') {
      return awayTeamLabel!;
    }
    return 'TBD';
  }

  String get stageName {
    switch (type.toLowerCase()) {
      case 'r32': return 'Round of 32';
      case 'r16': return 'Round of 16';
      case 'qf': return 'Quarterfinals';
      case 'sf': return 'Semifinals';
      case 'third': return 'Third Place Play-off';
      case 'final': return 'Grand Final';
      default: return 'Knockout Match';
    }
  }
}
