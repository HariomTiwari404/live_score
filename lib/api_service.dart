import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      'http://site.web.api.espn.com/apis/site/v2/sports/cricket/scorepanel'; // Make sure this is HTTPS
  //'https://site.web.api.espn.com/apis/site/v2/sports/cricket/scorepanel';

  Future<Map<String, dynamic>> fetchLiveScores() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse;
    } else {
      throw Exception('Failed to load live scores');
    }
  }

  Future<Map<String, dynamic>> fetchLeadersData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse;
    } else {
      throw Exception('Failed to load leaders data');
    }
  }

  Future<Map<String, dynamic>> fetchAthleteData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse;
    } else {
      throw Exception('Failed to load athlete data');
    }
  }

  Future<Map<String, dynamic>> fetchMatchDetails(int matchIndex) async {
    // Fetch live scores
    Map<String, dynamic> liveScores = await fetchLiveScores();

    // Parse match data
    Map<String, dynamic> matchData = parseMatchData(liveScores, matchIndex);

    // Initialize containers for leaders and athlete data
    List<Map<String, dynamic>> team1BatsmenData = [];
    List<Map<String, dynamic>> team2BatsmenData = [];
    List<Map<String, dynamic>> team1BowlersData = [];
    List<Map<String, dynamic>> team2BowlersData = [];

    // Fetch team 1 leaders and athlete data
    if (matchData['team1LeadersLink'] != 'No link available') {
      Map<String, dynamic> leadersData =
          await fetchLeadersData(matchData['team1LeadersLink']);
      var leaders = await fetchLeadersAndAthletes(leadersData);
      team1BatsmenData = leaders['batsmen'] ?? [];
      team1BowlersData = leaders['bowlers'] ?? [];
    }

    // Fetch team 2 leaders and athlete data
    if (matchData['team2LeadersLink'] != 'No link available') {
      Map<String, dynamic> leadersData =
          await fetchLeadersData(matchData['team2LeadersLink']);
      var leaders = await fetchLeadersAndAthletes(leadersData);
      team2BatsmenData = leaders['batsmen'] ?? [];
      team2BowlersData = leaders['bowlers'] ?? [];
    }

    // Combine and return all data
    return {
      'matchData': matchData,
      'team1BatsmenData': team1BatsmenData,
      'team2BatsmenData': team2BatsmenData,
      'team1BowlersData': team1BowlersData,
      'team2BowlersData': team2BowlersData,
    };
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchLeadersAndAthletes(
      Map<String, dynamic> leadersData) async {
    List<Map<String, dynamic>> batsmen = [];
    List<Map<String, dynamic>> bowlers = [];

    if (leadersData.containsKey('categories')) {
      for (var category in leadersData['categories']) {
        if (category.containsKey('name')) {
          if (category['name'] == 'runs') {
            if (category.containsKey('leaders') &&
                category['leaders'].isNotEmpty) {
              for (var leader in category['leaders']) {
                String value = leader['value'] ?? '0';
                String balls = leader['balls'] ?? '0';
                String fours = leader['fours'] ?? '0';
                String sixes = leader['sixes'] ?? '0';
                String order = leader['order'] ?? '0';

                String athleteUrl = leader['athlete']['\$ref'];
                Map<String, dynamic> athleteData =
                    await fetchAthleteData(athleteUrl);
                batsmen.add({
                  'value': value,
                  'athlete': athleteData,
                  'balls': balls,
                  'fours': fours,
                  'sixes': sixes,
                  'order': order,
                });
              }
            }
          } else if (category['name'] == 'wickets') {
            if (category.containsKey('leaders') &&
                category['leaders'].isNotEmpty) {
              for (var leader in category['leaders']) {
                String value = leader['runs'] ?? '0';
                String overs = leader['overs'] ?? '0';
                String maidens = leader['maidens'] ?? '0';
                String runs = leader['conceded'] ?? '0';
                String order = leader['order'] ?? '0';

                String athleteUrl = leader['athlete']['\$ref'];
                Map<String, dynamic> athleteData =
                    await fetchAthleteData(athleteUrl);
                bowlers.add({
                  'value': value,
                  'athlete': athleteData,
                  'overs': overs,
                  'maidens': maidens,
                  'runs': runs,
                  'order': order,
                });
              }
            }
          }
        }
      }
    }

    // Sort the batsmen and bowlers by the 'order' field
    batsmen
        .sort((a, b) => int.parse(a['order']).compareTo(int.parse(b['order'])));
    bowlers
        .sort((a, b) => int.parse(a['order']).compareTo(int.parse(b['order'])));

    return {'batsmen': batsmen, 'bowlers': bowlers};
  }

  Map<String, dynamic> parseMatchData(
      Map<String, dynamic> jsonResponse, int index) {
    try {
      final event = jsonResponse['scores'][0]['events'][index];
      final team1 = event['competitions'][0]['competitors'][0];
      final team2 = event['competitions'][0]['competitors'][1];

      final team1Name = team1['team']['shortDisplayName'] ?? 'Unknown';
      final team1Score = team1['score'] ?? '0';
      final team1Linescores = team1['linescores'];
      final team1Overs = team1Linescores.isNotEmpty
          ? team1Linescores[0]['overs']?.toString() ?? 'Yet To play'
          : 'Yet To play';
      final team1Wickets = team1Linescores.isNotEmpty
          ? team1Linescores[0]['wickets']?.toString() ?? 'Yet To play'
          : 'Yet To play';

      final team2Name = team2['team']['shortDisplayName'] ?? 'Unknown';
      final team2Score = team2['score'] ?? '0';
      final team2Linescores = team2['linescores'];
      final team2Overs = team2Linescores.isNotEmpty
          ? team2Linescores[0]['overs']?.toString() ?? 'Yet To play'
          : 'Yet To play';
      final team2Wickets = team2Linescores.isNotEmpty
          ? team2Linescores[0]['wickets']?.toString() ?? 'Yet To play'
          : 'Yet To play';

      final leagueName = jsonResponse['scores'][0]['leagues'][0]
              ['abbreviation'] ??
          'Unknown League';

      // Extract the leaders link
      final team1LeadersLink = team1['leaders']['\$ref'] ?? 'No link available';
      final team2LeadersLink = team2['leaders']['\$ref'] ?? 'No link available';

      final team1Logo = team1['team']['logo'] ?? '';
      final team2Logo = team2['team']['logo'] ?? '';

      return {
        'team1Name': team1Name,
        'team1Score': team1Score,
        'team1Overs': team1Overs,
        'team1Wickets': team1Wickets,
        'team2Name': team2Name,
        'team2Score': team2Score,
        'team2Overs': team2Overs,
        'team2Wickets': team2Wickets,
        'status': event['description'] ?? 'Status not available',
        'summary': event['competitions'][0]['status']['summary'] ??
            'Summary not available',
        'leagueName': leagueName,
        'team1LeadersLink': team1LeadersLink,
        'team2LeadersLink': team2LeadersLink,
        'team1Logo': team1Logo,
        'team2Logo': team2Logo,
      };
    } catch (e) {
      throw Exception('Failed to parse match data: $e');
    }
  }
}
