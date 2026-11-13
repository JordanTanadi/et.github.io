import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  void showHowToPlay() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('How to Play'),
        content: const Text(
          'geser katak ke kanan, kiri, atas, atau bawah untuk menggerakkan katak.\n\n'
          'Hindari kendaraan, gunakan batang kayu saat menyeberangi sungai.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'OK');
              context.push('/game');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Froggy Crosser')),
      drawer: myDrawer(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/katak.png', width: 150, height: 150),
            const SizedBox(height: 20),
            Text(
              'Welcome, $active_user!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: showHowToPlay,
              child: const Text(
                'PLAY GAME',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
