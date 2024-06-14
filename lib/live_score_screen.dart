import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';

class LiveScoresScreen extends StatefulWidget {
  const LiveScoresScreen({super.key});

  @override
  _LiveScoresScreenState createState() => _LiveScoresScreenState();
}

class _LiveScoresScreenState extends State<LiveScoresScreen> {
  Map<String, dynamic>? liveScore;
  Map<String, dynamic>? previousScore;
  bool isLoading = true;
  final ApiService _apiService = ApiService();
  Timer? refreshTimer;
  bool showIcon = false;
  int team1RunsScored = 0;
  int team2RunsScored = 0;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchLiveScores();
    const refreshInterval = Duration(seconds: 3);
    refreshTimer = Timer.periodic(refreshInterval, (_) {
      fetchLiveScores();
    });
  }

  Future<void> fetchLiveScores() async {
    try {
      final matchDetails = await _apiService.fetchMatchDetails(selectedIndex);

      setState(() {
        previousScore = liveScore;
        liveScore = matchDetails;
        isLoading = false;
      });

      int newTeam1RunsScored = getRunsScored(
        liveScore!['matchData']['team1Score'],
        previousScore?['matchData']['team1Score'],
      );
      int newTeam2RunsScored = getRunsScored(
        liveScore!['matchData']['team2Score'],
        previousScore?['matchData']['team2Score'],
      );

      if (newTeam1RunsScored > 0 || newTeam2RunsScored > 0) {
        setState(() {
          team1RunsScored = newTeam1RunsScored;
          team2RunsScored = newTeam2RunsScored;
          showIcon = true;
        });

        Timer(const Duration(seconds: 10), () {
          setState(() {
            showIcon = false;
          });
        });
      }
    } catch (e) {
      print('Error fetching live scores: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  int getRunsScored(String newScore, String? oldScore) {
    if (oldScore == null || oldScore.isEmpty) {
      return 0;
    }
    try {
      int newRuns = int.parse(newScore.split('/')[0]);
      int oldRuns = int.parse(oldScore.split('/')[0]);
      return newRuns - oldRuns;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Scor2ees'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Dropdown for selecting match
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<int>(
                    value: selectedIndex,
                    items: List.generate(5, (index) => index)
                        .map((index) => DropdownMenuItem<int>(
                              value: index,
                              child: Text('Match ${index + 1}'),
                            ))
                        .toList(),
                    onChanged: (int? newIndex) {
                      setState(() {
                        selectedIndex = newIndex!;
                        fetchLiveScores();
                      });
                    },
                  ),
                ),
                // Displaying live score details
                Expanded(
                  child: liveScore != null
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // League name
                                    Text(
                                      liveScore!['matchData']['leagueName'],
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.white54),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    // Team scores
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        if (liveScore!['matchData']
                                                ['team1Score'] !=
                                            null)
                                          buildTeamScore(
                                            liveScore!['matchData']
                                                ['team1Name'],
                                            liveScore!['matchData']
                                                ['team1Score'],
                                            liveScore!['matchData']
                                                ['team1Overs'],
                                            team1RunsScored,
                                            liveScore!['matchData']
                                                ['team1Logo'],
                                          ),
                                        if (liveScore!['matchData']
                                                ['team2Score'] !=
                                            null)
                                          buildTeamScore(
                                            liveScore!['matchData']
                                                ['team2Name'],
                                            liveScore!['matchData']
                                                ['team2Score'],
                                            liveScore!['matchData']
                                                ['team2Overs'],
                                            team2RunsScored,
                                            liveScore!['matchData']
                                                ['team2Logo'],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Icon for runs scored
                                    if (showIcon)
                                      Center(
                                        child: Icon(
                                          getRunIcon(team1RunsScored +
                                              team2RunsScored),
                                          size: 40,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    // Match summary and status
                                    Center(
                                      child: Text(
                                        liveScore!['matchData']['summary'],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        liveScore!['matchData']['status'],
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white54),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Tabs for displaying leaders
                                    DefaultTabController(
                                      length: 4,
                                      child: Column(
                                        children: [
                                          Container(
                                            color: Colors.black,
                                            child: TabBar(
                                              indicatorColor: Colors.white,
                                              tabs: [
                                                Tab(
                                                  text:
                                                      '${liveScore!['matchData']['team1Name']} Batsmen',
                                                ),
                                                Tab(
                                                  text:
                                                      '${liveScore!['matchData']['team1Name']} Bowlers',
                                                ),
                                                Tab(
                                                  text:
                                                      '${liveScore!['matchData']['team2Name']} Batsmen',
                                                ),
                                                Tab(
                                                  text:
                                                      '${liveScore!['matchData']['team2Name']} Bowlers',
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: 300, // Set a fixed height
                                            child: TabBarView(
                                              children: [
                                                ListView(
                                                  children: buildLeadersList(
                                                      liveScore![
                                                          'team1BatsmenData']),
                                                ),
                                                ListView(
                                                  children: buildLeadersList(
                                                      liveScore![
                                                          'team1BowlersData']),
                                                ),
                                                ListView(
                                                  children: buildLeadersList(
                                                      liveScore![
                                                          'team2BatsmenData']),
                                                ),
                                                ListView(
                                                  children: buildLeadersList(
                                                      liveScore![
                                                          'team2BowlersData']),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : const Center(child: Text('No live scores available')),
                ),
              ],
            ),
    );
  }

  // Function to build the list of leaders
  // Function to build the list of leaders
  // Function to build the list of leaders
  List<Widget> buildLeadersList(List<dynamic> leadersData) {
    // Ensure the order key is present
    if (leadersData.isNotEmpty && leadersData.first.containsKey('order')) {
      // Sort in ascending order based on the 'order' key using a custom comparator
      leadersData.sort((a, b) {
        final orderA = a['order'] != null ? int.tryParse(a['order']) ?? 0 : 0;
        final orderB = b['order'] != null ? int.tryParse(b['order']) ?? 0 : 0;
        return orderA.compareTo(orderB);
      });
    }

    // Build and return the list of widgets based on the sorted leadersData
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            const Expanded(
              flex: 3,
              child: Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Expanded(
              child: Text(
                'Runs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Expanded(
              child: Text(
                'Overs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (leadersData.isNotEmpty &&
                leadersData.first.containsKey('fours'))
              const Expanded(
                child: Text(
                  '4s',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (leadersData.isNotEmpty &&
                leadersData.first.containsKey('sixes'))
              const Expanded(
                child: Text(
                  '6s',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
      ...leadersData.map((leader) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        leader['athlete']['headshot']['href'],
                      ),
                      radius: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leader['athlete']['name'],
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Text(leader['value'].toString())),
              Expanded(
                child: Text(
                  leader.containsKey('balls')
                      ? leader['balls'].toString()
                      : leader['overs'].toString(),
                ),
              ),
              if (leader.containsKey('fours'))
                Expanded(child: Text(leader['fours'].toString())),
              if (leader.containsKey('sixes'))
                Expanded(child: Text(leader['sixes'].toString())),
            ],
          ),
        );
      }),
    ];
  }

  // Function to get the appropriate icon based on runs scored
  IconData getRunIcon(int runs) {
    switch (runs) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      case 4:
        return Icons.looks_4;
      case 6:
        return Icons.six_k;
      default:
        return Icons.circle;
    }
  }

  // Function to build the team score widget
  Widget buildTeamScore(String teamName, String teamScore, String teamOvers,
      int runsScored, String teamLogo) {
    return Column(
      children: [
        Image.network(
          teamLogo,
          height: 50,
          width: 50,
        ),
        const SizedBox(height: 8),
        Text(
          teamName,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          teamScore,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Overs: $teamOvers',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }
}
