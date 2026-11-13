import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggy_crosser/screen/game.dart';
import 'package:froggy_crosser/screen/highscore.dart';
import 'package:froggy_crosser/screen/home.dart';
import 'package:froggy_crosser/screen/login.dart';
import 'package:froggy_crosser/screen/result.dart';

GoRouter getAppRouter() {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: isLoggedIn,
    redirect: (context, state) {
      final login = state.uri.path == "/login";
      if (!isLoggedIn.value && !login) {
        return "/login";
      }
      if (isLoggedIn.value && login) {
        return "/";
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const Home(),
      ),
      GoRoute(
        path: '/game',
        name: 'game',
        builder: (context, state) => const Game(),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final score =
              int.tryParse(state.uri.queryParameters['score'] ?? '0') ?? 0;
          final frogsCrossed =
              int.tryParse(state.uri.queryParameters['frogs'] ?? '0') ?? 0;

          return Result(score: score, frogsCrossed: frogsCrossed);
        },
      ),
      GoRoute(
        path: '/highscore',
        name: 'highscore',
        builder: (context, state) => const Highscore(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Login(),
      ),
    ],
  );
}

String active_user = "";
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await checkUser();
  runApp(const MyApp());
}

Future<void> checkUser() async {
  final prefs = await SharedPreferences.getInstance();
  active_user = prefs.getString("user_id") ?? '';
  isLoggedIn.value = active_user.isNotEmpty;
}

void doLogout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("user_id");
  isLoggedIn.value = false;
}

Drawer myDrawer(BuildContext context) {
  return Drawer(
    elevation: 16.0,
    child: Column(
      children: <Widget>[
        UserAccountsDrawerHeader(
          accountName: Text(active_user),
          accountEmail: Text("$active_user@gmail.com"),
          currentAccountPicture: CircleAvatar(
            child: Image.asset('assets/images/katak.png', fit: BoxFit.cover),
          ),
        ),
        ListTile(
          title: const Text("High Score"),
          leading: const Icon(Icons.leaderboard),
          onTap: () {
            Navigator.pop(context);
            context.pushNamed('highscore');
          },
        ),
        ListTile(
          title: const Text("Logout"),
          leading: const Icon(Icons.logout),
          onTap: () {
            doLogout();
          },
        ),
      ],
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Froggy Crosser',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      routerConfig: getAppRouter(),
    );
  }
}
