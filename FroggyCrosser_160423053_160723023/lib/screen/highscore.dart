import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:froggy_crosser/class/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Highscore extends StatefulWidget {
  const Highscore({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HighscoreState();
  }
}

class _HighscoreState extends State<Highscore> {
  List<Player> _highScores = [];
  bool _show = false;

  @override
  void initState() {
    super.initState();
    getHighScores();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _show = true);
    });
  }


  Color rankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFC107); 
      case 1:
        return const Color(0xFF9E9E9E); 
      case 2:
        return const Color(0xFFBF6B2B); 
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> getHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('high_scores');

    List<Player> scores = [];
    if (data != null && data.isNotEmpty) {
      scores = (jsonDecode(data) as List)
          .map((json) => Player.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    // tampilkan 3 skor teratas saja
    scores.sort((a, b) => b.score.compareTo(a.score));
    if (scores.length > 3) {
      scores = scores.sublist(0, 3);
    }

    if (!mounted) return;

    setState(() {
      _highScores = scores;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('High Score')),
      body: _highScores.isEmpty
          ? const Center(
              child: Text(
                'Belum ada High Score',
                style: TextStyle(fontSize: 24),
              ),
            )
          : AnimatedOpacity(
              opacity: _show ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeIn,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _highScores.length,
                itemBuilder: (context, index) {
                  final player = _highScores[index];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: rankColor(index),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        player.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Rank ${index + 1}'),
                      trailing: Text(
                        '${player.score}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
