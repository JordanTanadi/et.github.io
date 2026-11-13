import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../class/player.dart';
import '../main.dart';

// benda yang bergerak di layar: batang kayu / kendaraan
class _Mover {
  _Mover({
    required this.x,
    required this.width,
    required this.speed,
    required this.direction,
    required this.asset,
  });

  double x;
  final double width;
  final double speed;
  final int direction;
  final String asset;
}

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GameState();
  }
}

class _GameState extends State<Game> {
  int _hitung = 60;
  final int _initValue = 60;
  int _frogsCrossed = 0;

  // ukuran papan: 6 kolom x 9 baris
  final int _columns = 6;
  final int _rows = 9;
  final int _startRow = 8;

  // peta jalur: daftar benda per baris
  final Map<int, List<_Mover>> _lanes = {
    1: [
      _Mover(
        x: 0,
        width: 2,
        speed: 0.7,
        direction: 1,
        asset: 'assets/images/kayu_sedang.png',
      ),
      _Mover(
        x: 3.5,
        width: 2,
        speed: 0.7,
        direction: 1,
        asset: 'assets/images/kayu_sedang.png',
      ),
    ],
    2: [
      _Mover(
        x: 1,
        width: 1.7,
        speed: 0.8,
        direction: -1,
        asset: 'assets/images/kayu_kecil.png',
      ),
      _Mover(
        x: 4.5,
        width: 1.7,
        speed: 0.8,
        direction: -1,
        asset: 'assets/images/kayu_kecil.png',
      ),
    ],
    3: [
      _Mover(
        x: 0,
        width: 2.2,
        speed: 0.5,
        direction: 1,
        asset: 'assets/images/kayu_besar.png',
      ),
      _Mover(
        x: 3.5,
        width: 2.2,
        speed: 0.5,
        direction: 1,
        asset: 'assets/images/kayu_besar.png',
      ),
    ],
    5: [
      _Mover(
        x: 0,
        width: 1.2,
        speed: 1.4,
        direction: 1,
        asset: 'assets/images/mobil_balap.png',
      ),
      _Mover(
        x: 3.2,
        width: 1.2,
        speed: 1.4,
        direction: 1,
        asset: 'assets/images/mobil_balap.png',
      ),
    ],
    6: [
      _Mover(
        x: 1,
        width: 1.6,
        speed: 0.9,
        direction: -1,
        asset: 'assets/images/mobil.png',
      ),
      _Mover(
        x: 4.5,
        width: 1.6,
        speed: 0.9,
        direction: -1,
        asset: 'assets/images/mobil.png',
      ),
    ],
    7: [
      _Mover(
        x: 0.5,
        width: 1.8,
        speed: 0.55,
        direction: 1,
        asset: 'assets/images/truk.png',
      ),
      _Mover(
        x: 3.8,
        width: 1.8,
        speed: 0.55,
        direction: 1,
        asset: 'assets/images/truk.png',
      ),
    ],
  };

  static const String _frogIdle = 'assets/images/katak.png';
  static const String _frogHit = 'assets/images/katak_mati.png';

  int _frogRow = 8;
  double _frogX = 3;
  bool _isDead = false;
  bool _gameOver = false;

  final FocusNode _gameFocusNode = FocusNode();

  double _dragX = 0;
  double _dragY = 0;

  late Timer _timer, _timer2;
  Timer? _deathTimer;

  final AudioPlayer _musicPlayer = AudioPlayer();
  bool _audioStarted = false;

  // dipakai bergantian supaya efek tidak saling memotong
  final List<AudioPlayer> _effectPlayers = List.generate(
    4,
    (_) => AudioPlayer(),
  );
  int _effectIndex = 0;

  @override
  void initState() {
    super.initState();
    randomizeLanePositions();
    startTimer();
  }

  // geser katak 4 arah pakai drag
  void swipe(DragEndDetails details) {
    if (_isDead || _gameOver) return;
    startAudio();

    final velocity = details.velocity.pixelsPerSecond;
    var horizontal = _dragX;
    var vertical = _dragY;

    // geser terlalu kecil -> pakai arah lemparan jari
    if (horizontal.abs() < 20 && vertical.abs() < 20) {
      horizontal = velocity.dx;
      vertical = velocity.dy;
    }
    if (horizontal.abs() < 20 && vertical.abs() < 20) return;

    setState(() {
      if (horizontal.abs() > vertical.abs()) {
        _frogX += horizontal > 0 ? 1 : -1;
      } else {
        _frogRow += vertical > 0 ? 1 : -1;
      }

      _frogRow = _frogRow.clamp(0, _rows - 1);
      _frogX = _frogX.clamp(0.5, _columns - 0.5);
    });

    playEffect('sound_lompat.mp3');
  }

  // ketuk katak untuk maju 1 baris
  void tapFrog() {
    _gameFocusNode.requestFocus();
    moveFrog(0, -1);
  }

  // pindahkan katak 1 langkah
  void moveFrog(int dx, int dy) {
    if (_isDead || _gameOver) return;
    startAudio();

    setState(() {
      _frogRow = (_frogRow + dy).clamp(0, _rows - 1);
      _frogX = (_frogX + dx).clamp(0.5, _columns - 0.5);
    });

    playEffect('sound_lompat.mp3');
  }

  // tombol wasd / panah
  KeyEventResult handleGameKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    int dx = 0;
    int dy = 0;

    if (key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.arrowUp) {
      dy = -1;
    } else if (key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.arrowDown) {
      dy = 1;
    } else if (key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.arrowLeft) {
      dx = -1;
    } else if (key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.arrowRight) {
      dx = 1;
    } else {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      moveFrog(dx, dy);
    }

    return KeyEventResult.handled;
  }

  Future<void> checkTopScore() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('high_scores') ?? '';
    List<Player> scores = [];

    if (data.isNotEmpty) {
      scores = (jsonDecode(data) as List)
          .map((json) => Player.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    // ambil skor pemain yang login
    final existingIndex = scores.indexWhere(
      (player) => player.username == active_user,
    );

    if (existingIndex != -1) {
      // skor lama tidak ditimpa kalau lebih rendah
      if (_frogsCrossed > scores[existingIndex].score) {
        scores[existingIndex] = Player(
          username: active_user,
          score: _frogsCrossed,
        );
      }
    } else {
      scores.add(Player(username: active_user, score: _frogsCrossed));
    }

    // urutkan dari tertinggi, simpan 3 teratas
    scores.sort((a, b) => b.score.compareTo(a.score));

    if (scores.length > 3) {
      scores = scores.sublist(0, 3);
    }

    await prefs.setString(
      'high_scores',
      jsonEncode(scores.map((player) => player.toJson()).toList()),
    );
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_hitung == 0) {
        // waktu sudah habis -> tutup permainan
        endGame();

        // matikan timer
        timer.cancel();
        _timer2.cancel();

        // set ulang var _hitung
        _hitung = 0;
      } else {
        setState(() {
          _hitung--;
        });
      }
    });

    _timer2 = Timer.periodic(Duration(milliseconds: 100), (timer) {
      // gerakkan dunia dan cek tabrakan
      moveWorld();
    });
  }

  // musik latar diputar setelah interaksi pertama
  void startAudio() {
    if (_audioStarted) return;
    _audioStarted = true;
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _musicPlayer.play(AssetSource('sound/sound_ingame.mp3'));
  }

  // mainkan efek pakai 4 player bergantian
  void playEffect(String soundFile) {
    final player = _effectPlayers[_effectIndex];
    _effectIndex = (_effectIndex + 1) % _effectPlayers.length;
    player.stop();
    player.play(AssetSource('sound/$soundFile'));
  }

  // posisi awal tiap baris dibuat acak
  void randomizeLanePositions() {
    final random = math.Random();

    for (final movers in _lanes.values) {
      final offset = random.nextDouble() * _columns;
      for (final mover in movers) {
        mover.x = (mover.x + offset) % _columns;
      }
    }
  }

  void moveWorld() {
    if (!mounted || _gameOver) return;

    setState(() {
      // gerakkan semua kendaraan dan batang kayu
      for (final movers in _lanes.values) {
        for (final mover in movers) {
          mover.x += mover.speed * mover.direction * 0.1;
          if (mover.direction > 0 && mover.x > _columns) {
            mover.x = -mover.width;
          } else if (mover.direction < 0 && mover.x + mover.width < 0) {
            mover.x = _columns.toDouble();
          }
        }
      }

      if (_isDead) return;

      // cek katak sesuai barisnya
      if (_frogRow >= 1 && _frogRow <= 3) {
        checkWater();
      } else if (_frogRow >= 5 && _frogRow <= 7) {
        checkVehicles();
      } else if (_frogRow == 0) {
        // sampai tujuan: tambah poin lalu ulang
        _frogsCrossed++;
        playEffect('sound_selesai.mp3');
        resetFrog();
      }
    });
  }

  // katak di baris sungai: harus menumpang kayu
  void checkWater() {
    _Mover? log;
    for (final item in _lanes[_frogRow] ?? <_Mover>[]) {
      if (_frogX >= item.x && _frogX <= item.x + item.width) {
        log = item;
        break;
      }
    }

    // tidak ada pijakan -> tenggelam
    if (log == null) {
      die('sound_tenggelam.mp3');
      return;
    }

    // ikut kayu; keluar layar -> tenggelam
    _frogX += log.speed * log.direction * 0.1;
    if (_frogX < 0.5 || _frogX > _columns - 0.5) {
      die('sound_tenggelam.mp3');
    }
  }

  // katak di baris jalan: boleh tertabrak
  void checkVehicles() {
    final frogLeft = _frogX - 0.35;
    final frogRight = _frogX + 0.35;

    for (final vehicle in _lanes[_frogRow] ?? <_Mover>[]) {
      final vehicleLeft = vehicle.x + vehicle.width * 0.18;
      final vehicleRight = vehicle.x + vehicle.width * 0.82;

      if (frogLeft < vehicleRight && frogRight > vehicleLeft) {
        die('sound_ketabrak.mp3');
        return;
      }
    }
  }

  void die(String soundFile) {
    if (_isDead) return;
    _isDead = true;
    playEffect(soundFile);

    // 500 ms kemudian posisi katak direset
    _deathTimer?.cancel();
    _deathTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _gameOver) return;
      setState(resetFrog);
    });
  }

  void resetFrog() {
    _frogRow = _startRow;
    _frogX = _columns / 2;
    _isDead = false;
  }

  Future<void> endGame() async {
    if (_gameOver) return;
    _gameOver = true;

    // matikan timer
    _timer.cancel();
    _timer2.cancel();
    _deathTimer?.cancel();

    playEffect('sound_gameover.mp3');

    // tunggu suara game over terdengar
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // cek dan simpan top score
    await checkTopScore();
    if (!mounted) return;

    context.go('/result?score=$_frogsCrossed&frogs=$_frogsCrossed');
  }

  @override
  void dispose() {
    // matikan timer
    _timer.cancel();
    _timer2.cancel();
    _deathTimer?.cancel();
    _hitung = 0;
    _gameFocusNode.dispose();

    _musicPlayer.dispose();
    for (final player in _effectPlayers) {
      player.dispose();
    }
    super.dispose();
  }

  String formatTime(int hitung) {
    var hours = (hitung ~/ 3600).toString().padLeft(2, '0');
    var minutes = ((hitung % 3600) ~/ 60).toString().padLeft(2, '0');
    var seconds = (hitung % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  // papan diberi ukuran tetap: lebar layar, tinggi rasio 6 x 9
  Widget buildBoard(double boardWidth, double boardHeight) {
    final double cellWidth = boardWidth / _columns;
    final double cellHeight = boardHeight / _rows;

    return GestureDetector(
      onPanStart: (_) {
        _gameFocusNode.requestFocus();
        _dragX = 0;
        _dragY = 0;
      },
      onPanUpdate: (details) {
        _dragX += details.delta.dx;
        _dragY += details.delta.dy;
      },
      onPanEnd: swipe,
      child: Stack(
        children: [
          // latar belakang 9 baris: tanah, air, rumput, jalan
          Column(
            children: [
              Image.asset(
                'assets/images/tanah.png',
                width: double.infinity,
                height: cellHeight,
                fit: BoxFit.cover,
              ),
              Image.asset(
                'assets/images/air.png',
                width: double.infinity,
                height: cellHeight,
                fit: BoxFit.cover,
              ),
              Image.asset(
                'assets/images/air.png',
                width: double.infinity,
                height: cellHeight,
                fit: BoxFit.cover,
              ),
              Image.asset(
                'assets/images/air.png',
                width: double.infinity,
                height: cellHeight,
                fit: BoxFit.cover,
              ),
              Image.asset(
                'assets/images/rumput.png',
                width: double.infinity,
                height: cellHeight,
                fit: BoxFit.cover,
              ),
              Image.asset(
                'assets/images/jalan.png',
                width: double.infinity,
                height: cellHeight,
                fit: BoxFit.cover,
              ),
              Image.asset(
                'assets/images/jalan.png',
                width: double.infinity,
                height: cellHeight,
                fit: BoxFit.cover,
              ),
              Image.asset(
                'assets/images/jalan.png',
                width: double.infinity,
                height: cellHeight,
                fit: BoxFit.cover,
              ),
              Image.asset(
                'assets/images/rumput.png',
                width: double.infinity,
                height: cellHeight,
                fit: BoxFit.cover,
              ),
            ],
          ),

          // kendaraan dan batang kayu yang bergerak
          for (final entry in _lanes.entries)
            for (final mover in entry.value)
              Positioned(
                left: mover.x * cellWidth,
                top: entry.key * cellHeight,
                width: mover.width * cellWidth,
                height: cellHeight,
                child: Image.asset(mover.asset, fit: BoxFit.fill),
              ),

          // katak digeser pakai animasi
          AnimatedPositioned(
            duration: const Duration(milliseconds: 120),
            left: (_frogX - 0.5) * cellWidth,
            top: _frogRow * cellHeight,
            width: cellWidth,
            height: cellHeight,
            child: GestureDetector(
              onTap: tapFrog,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Image.asset(
                  _isDead ? _frogHit : _frogIdle,
                  key: ValueKey<String>(_isDead ? 'dead' : 'idle'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // hitung lebar-tinggi papan: sel harus persegi dan tidak meluber
  Size ukuranPapan(BuildContext context) {
    final Size layar = MediaQuery.of(context).size;
    final double notch = MediaQuery.of(context).padding.top;

    // tinggi maksimal papan supaya muat di bawah AppBar
    double tinggi = layar.height - 96 - notch;
    double lebar = tinggi * _columns / _rows;

    // kalau kelebaran, batasi dari lebar layar
    if (lebar > layar.width) {
      lebar = layar.width;
      tinggi = lebar * _rows / _columns;
    }

    return Size(lebar, tinggi);
  }

  @override
  Widget build(BuildContext context) {
    final Size papan = ukuranPapan(context);

    return Focus(
      focusNode: _gameFocusNode,
      autofocus: true,
      onKeyEvent: handleGameKey,
      child: Scaffold(
        appBar: AppBar(title: Text('Score: $_frogsCrossed')),
        body: Center(
          child: Column(
            children: <Widget>[
              LinearPercentIndicator(
                center: Text(formatTime(_hitung)),
                width: MediaQuery.of(context).size.width,
                lineHeight: 20.0,
                percent: 1 - (_hitung / _initValue),
                backgroundColor: Colors.grey,
                progressColor: Colors.red,
              ),
              SizedBox(
                height: papan.height,
                width: papan.width,
                child: buildBoard(papan.width, papan.height),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
