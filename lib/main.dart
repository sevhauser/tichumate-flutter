import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flare_splash_screen/flare_splash_screen.dart';

import 'package:tichumate/database.dart';
import 'package:tichumate/views/game.dart';
import 'package:tichumate/views/gameedit.dart';
import 'package:tichumate/views/home.dart';
import 'package:tichumate/views/newgame.dart';
import 'package:tichumate/views/player.dart';
import 'package:tichumate/views/round.dart';
import 'package:tichumate/views/settings.dart';
import 'package:tichumate/views/debug.dart';

void main() async {
  var tichudb = TichuDB();
  await tichudb.init();
  runApp(MyApp());
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'TichuMate',
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'RobotoCondensed',
          primaryColor: Color(0xFF1a1a1f),
          accentColor: Color(0xFFf2c109),
        ),
        initialRoute: '/init',
        routes: {
          '/init': (context) => SplashScreen.callback(
                backgroundColor: Theme.of(context).primaryColor,
                name: 'assets/splash_logo.flr',
                width: 300,
                until: () => Future.delayed(Duration(seconds: 4)),
                onSuccess: (_) => Navigator.of(context).pop(),
                onError: (_, __) {},
                startAnimation: 'start',
              ),
          '/': (context) => HomeView(),
          '/player': (context) => PlayerView(),
          '/newgame': (context) => NewGameView(),
          '/game': (context) => GameView(),
          '/editgame': (context) => GameEditView(),
          '/round': (context) => RoundView(),
          '/settings': (context) => SettingsView(),
          '/debug': (context) => DataDebugView(),
        },
        navigatorObservers: [
          routeObserver
        ],
        localizationsDelegates: [
          FlutterI18nDelegate(useCountryCode: false, fallbackFile: 'en'),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ]);
  }
}
