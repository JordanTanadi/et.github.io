import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Result extends StatefulWidget {
  final int score;
  final int frogsCrossed;

  const Result({super.key, required this.score, required this.frogsCrossed});

  @override
  State<StatefulWidget> createState() {
    return _ResultState();
  }
}

class _ResultState extends State<Result> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    // animasi masuk setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _show = true);
    });
  }

  // title sesuai jumlah katak yang diseberangkan
  String getPlayerTitle(int frogsCrossed) {
    if (frogsCrossed >= 5) {
      return 'Apex Amphibian';
    } else if (frogsCrossed == 4) {
      return 'Highway Navigator';
    } else if (frogsCrossed == 3) {
      return 'Agile Hopper';
    } else if (frogsCrossed == 2) {
      return 'Pond Explorer';
    } else if (frogsCrossed == 1) {
      return 'Daring Tadpole';
    } else {
      return 'Unlucky Amphibian';
    }
  }

  void playAgain() {
    context.go('/game');
  }

  void openHighScores() {
    context.push('/highscore');
  }

  void goToMainMenu() {
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final title = getPlayerTitle(widget.frogsCrossed);
    return Scaffold(
      appBar: AppBar(title: const Text('Game result')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedOpacity(
            opacity: _show ? 1 : 0,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeIn,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Game Over!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text('🐸', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 30),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: <Widget>[
                        const Text('Score', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<int>(
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOut,
                          tween: IntTween(begin: 0, end: widget.score),
                          builder: (context, value, child) => Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Frogs Crossed',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<int>(
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOut,
                          tween: IntTween(begin: 0, end: widget.frogsCrossed),
                          builder: (context, value, child) => Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Title', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: playAgain,
                    child: const Text('Play Again'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: openHighScores,
                    child: const Text('High Scores'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: goToMainMenu,
                    child: const Text('Main Menu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
