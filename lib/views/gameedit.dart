import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/components/gameform.dart';
import 'package:tichumate/utils/gamemanager.dart';
import 'package:tichumate/views/game.dart';
import 'package:tichumate/components/teamform.dart';

class GameEditView extends StatelessWidget {
  const GameEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final GameViewArguments args =
        ModalRoute.of(context)!.settings.arguments as GameViewArguments;
    return _GameEditView(gameId: args.gameId);
  }
}

class _GameEditView extends StatefulWidget {
  final int gameId;

  const _GameEditView({
    required this.gameId,
  });

  @override
  _GameEditViewState createState() => _GameEditViewState();
}

class _GameEditViewState extends State<_GameEditView> {
  final _team1FormKey = GlobalKey<FormState>(),
      _team2FormKey = GlobalKey<FormState>(),
      _gameFormKey = GlobalKey<FormState>();
  bool _loaded = false;
  late GameManager _gm;

  _GameEditViewState();

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  void _loadGame() async {
    _gm = GameManager(gameId: widget.gameId);
    await _gm.init();
    setState(() {
      _loaded = true;
    });
  }

  Future<void> _save() async {
    _team1FormKey.currentState?.save();
    _team2FormKey.currentState?.save();
    _gameFormKey.currentState?.save();
    await _gm.save();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loaded
          ? ListView(scrollDirection: Axis.vertical, children: <Widget>[
              Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Theme.of(context).primaryColor,
                  child: Center(
                    child: Text(
                        '${FlutterI18n.translate(context, 'team.team').toUpperCase()} 1',
                        style: const TextStyle(fontSize: 16)),
                  )),
              Container(
                padding: const EdgeInsets.all(16),
                child: TeamForm(
                  formKey: _team1FormKey,
                  team: _gm.team1.team!,
                  teamNameCallback: (name) {
                    _gm.team1.team!.name = name!;
                  },
                  playersCallback: (players) {
                    _gm.team1.team!.players = players!;
                  },
                ),
              ),
              Container(
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                        '${FlutterI18n.translate(context, 'team.team').toUpperCase()} 2',
                        style: const TextStyle(fontSize: 16)),
                  )),
              Container(
                padding: const EdgeInsets.all(16),
                child: TeamForm(
                  formKey: _team2FormKey,
                  team: _gm.team2.team!,
                  teamNameCallback: (name) {
                    _gm.team2.team!.name = name!;
                  },
                  playersCallback: (players) {
                    _gm.team2.team!.players = players!;
                  },
                ),
              ),
              Container(
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                        FlutterI18n.translate(context, 'game.rules.rules')
                            .toUpperCase(),
                        style: const TextStyle(fontSize: 16)),
                  )),
              Container(
                padding: const EdgeInsets.all(16),
                child: GameForm(
                  formKey: _gameFormKey,
                  game: _gm.game,
                  ruleCallback: (rule) {
                    _gm.game.rule = rule!;
                  },
                  winScoreCallback: (score) {
                    _gm.game.winScore = score!;
                  },
                ),
              ),
            ])
          : Container(),
      bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).primaryColor,
          child: SizedBox(
            height: 56,
            child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
              TextButton(
                child: Text(
                    FlutterI18n.translate(context, 'ui.cancel').toUpperCase(),
                    style: TextStyle(color: Colors.red.shade500)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              TextButton(
                child: Text(
                    FlutterI18n.translate(context, 'ui.save').toUpperCase(),
                    style: TextStyle(color: Colors.green.shade500)),
                onPressed: () => _save(),
              ),
            ]),
          )),
    );
  }
}
