import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


import 'package:tichumate/theme.dart';
import 'package:tichumate/state/database.dart';
import 'package:tichumate/utils/routing.dart';
import 'package:tichumate/views/game.dart';
import 'package:tichumate/views/gameedit.dart';
import 'package:tichumate/views/home.dart';
import 'package:tichumate/views/newgame.dart';
import 'package:tichumate/views/player.dart';
import 'package:tichumate/views/round.dart';
import 'package:tichumate/views/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var tichudb = TichuDB();
  await tichudb.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TichuMate',
      theme: TichuMateTheme.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeView(),
        '/player': (context) => const PlayerView(),
        '/newgame': (context) => const NewGameView(),
        '/game': (context) => const GameView(),
        '/editgame': (context) => const GameEditView(),
        '/round': (context) => const RoundView(),
        '/settings': (context) => const SettingsView(),
      },
      navigatorObservers: [routeObserver],
      localizationsDelegates: [
        FlutterI18nDelegate(translationLoader: FileTranslationLoader()),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
    );
  }
}
