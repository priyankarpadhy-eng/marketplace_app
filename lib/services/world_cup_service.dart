import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:market_app/models/world_cup_match.dart';

class WorldCupService {
  static final WorldCupService instance = WorldCupService._internal();
  WorldCupService._internal();

  Future<List<WorldCupMatch>> fetchKnockoutMatches() async {
    try {
      final response = await http.get(Uri.parse('https://worldcup26.ir/get/games'))
          .timeout(const Duration(seconds: 8));
          
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('games')) {
          final games = decoded['games'];
          if (games is List) {
            final parsed = games
                .map((json) => WorldCupMatch.fromJson(json as Map<String, dynamic>))
                .where((m) => m.type.toLowerCase() != 'group')
                .toList();
            if (parsed.isNotEmpty) return parsed;
          }
        }
      }
      return _getMockMatches();
    } catch (_) {
      return _getMockMatches();
    }
  }

  List<WorldCupMatch> _getMockMatches() {
    return [
      WorldCupMatch(
        id: '73',
        homeTeamId: '1',
        awayTeamId: '2',
        homeScore: 3,
        awayScore: 2,
        homeScorers: 'Messi 12\', Alvarez 45\', Martinez 88\'',
        awayScorers: 'Pulisic 34\', Balogun 70\'',
        group: 'R32',
        matchday: '4',
        localDate: '06/28/2026 12:00',
        stadiumId: '16',
        finished: true,
        timeElapsed: '90\'',
        type: 'r32',
        homeTeamNameEn: 'Argentina',
        awayTeamNameEn: 'USA',
      ),
      WorldCupMatch(
        id: '74',
        homeTeamId: '3',
        awayTeamId: '4',
        homeScore: 1,
        awayScore: 2,
        homeScorers: 'Vinicius Jr 55\'',
        awayScorers: 'Mbappe 22\', Griezmann 80\'',
        group: 'R32',
        matchday: '4',
        localDate: '06/28/2026 15:00',
        stadiumId: '11',
        finished: true,
        timeElapsed: '90\'',
        type: 'r32',
        homeTeamNameEn: 'Brazil',
        awayTeamNameEn: 'France',
      ),
      WorldCupMatch(
        id: '75',
        homeTeamId: '5',
        awayTeamId: '6',
        homeScore: 1,
        awayScore: 1,
        homeScorers: 'Saka 42\'',
        awayScorers: 'Musiala 65\'',
        group: 'R32',
        matchday: '4',
        localDate: '06/28/2026 18:00',
        stadiumId: '1',
        finished: false,
        timeElapsed: 'live',
        type: 'r32',
        homeTeamNameEn: 'England',
        awayTeamNameEn: 'Germany',
      ),
      WorldCupMatch(
        id: '76',
        homeTeamId: '7',
        awayTeamId: '8',
        homeScore: 0,
        awayScore: 0,
        homeScorers: '',
        awayScorers: '',
        group: 'R32',
        matchday: '4',
        localDate: '06/29/2026 12:00',
        stadiumId: '2',
        finished: false,
        timeElapsed: 'notstarted',
        type: 'r32',
        homeTeamNameEn: 'Spain',
        awayTeamNameEn: 'Portugal',
      ),
      WorldCupMatch(
        id: '89',
        homeTeamId: '0',
        awayTeamId: '0',
        homeScore: 0,
        awayScore: 0,
        homeScorers: '',
        awayScorers: '',
        group: 'R16',
        matchday: '5',
        localDate: '07/04/2026 12:00',
        stadiumId: '3',
        finished: false,
        timeElapsed: 'notstarted',
        type: 'r16',
        homeTeamLabel: 'Winner Match 73',
        awayTeamLabel: 'Winner Match 74',
      ),
      WorldCupMatch(
        id: '97',
        homeTeamId: '0',
        awayTeamId: '0',
        homeScore: 0,
        awayScore: 0,
        homeScorers: '',
        awayScorers: '',
        group: 'QF',
        matchday: '6',
        localDate: '07/09/2026 12:00',
        stadiumId: '4',
        finished: false,
        timeElapsed: 'notstarted',
        type: 'qf',
        homeTeamLabel: 'Winner Match 89',
        awayTeamLabel: 'Winner Match 90',
      ),
      WorldCupMatch(
        id: '101',
        homeTeamId: '0',
        awayTeamId: '0',
        homeScore: 0,
        awayScore: 0,
        homeScorers: '',
        awayScorers: '',
        group: 'SF',
        matchday: '7',
        localDate: '07/14/2026 12:00',
        stadiumId: '5',
        finished: false,
        timeElapsed: 'notstarted',
        type: 'sf',
        homeTeamLabel: 'Winner Match 97',
        awayTeamLabel: 'Winner Match 98',
      ),
      WorldCupMatch(
        id: '104',
        homeTeamId: '0',
        awayTeamId: '0',
        homeScore: 0,
        awayScore: 0,
        homeScorers: '',
        awayScorers: '',
        group: 'FINAL',
        matchday: '9',
        localDate: '07/19/2026 12:00',
        stadiumId: '11',
        finished: false,
        timeElapsed: 'notstarted',
        type: 'final',
        homeTeamLabel: 'Winner Match 101',
        awayTeamLabel: 'Winner Match 102',
      ),
    ];
  }
}
