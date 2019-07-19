import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/components/gameform.dart';
import 'package:tichumate/utils/gamemanager.dart';
import 'package:tichumate/views/game.dart';
import 'package:tichumate/components/teamform.dart';

class GameEditView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final GameViewArguments args = ModalRoute.of(context).settings.arguments;
    return _GameEditView(gameId: args.gameId);
  }
}

class _GameEditView extends StatefulWidget {
  final int gameId;

  _GameEditView({
    @required this.gameId,
    Key key,
  }) : super(key: key);

  @override
  _GameEditViewState createState() => _GameEditViewState(gameId: gameId);
}

class _GameEditViewState extends State<_GameEditView> {
  final int gameId;
  final _team1FormKey = GlobalKey<FormState>(),
      _team2FormKey = GlobalKey<FormState>(),
      _gameFormKey = GlobalKey<FormState>();
  bool _loaded = false;
  GameManager _gm;

  _GameEditViewState({
    @required this.gameId,
  });

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  void _loadGame() async {
    _gm = GameManager(gameId: gameId);
    await _gm.init();
    setState(() {
      _loaded = true;
    });
  }

  Future<void> _save() async {
    _team1FormKey.currentState..save();
    _team2FormKey.currentState..save();
    _gameFormKey.currentState..save();
    await _gm.save();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loaded
          ? ListView(scrollDirection: Axis.vertical, children: <Widget>[
              Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  color: Theme.of(context).primaryColor,
                  child: Center(
                    child: Text(
                        FlutterI18n.translate(context, 'team.team')
                                .toUpperCase() +
                            ' 1',
                        style: TextStyle(fontSize: 16)),
                  )),
              Container(
                padding: EdgeInsets.all(16),
                child: TeamForm(
                  formKey: _team1FormKey,
                  team: _gm.team1.team,
                  teamNameCallback: (name) {
                    _gm.team1.team.name = name;
                  },
                  playersCallback: (players) {
                    _gm.team1.team.players = players;
                  },
                ),
              ),
              Container(
                  color: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                        FlutterI18n.translate(context, 'team.team')
                                .toUpperCase() +
                            ' 2',
                        style: TextStyle(fontSize: 16)),
                  )),
              Container(
                padding: EdgeInsets.all(16),
                child: TeamForm(
                  formKey: _team2FormKey,
                  team: _gm.team2.team,
                  teamNameCallback: (name) {
                    _gm.team2.team.name = name;
                  },
                  playersCallback: (players) {
                    _gm.team2.team.players = players;
                  },
                ),
              ),
              Container(
                  color: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                        FlutterI18n.translate(context, 'game.rules.rules')
                            .toUpperCase(),
                        style: TextStyle(fontSize: 16)),
                  )),
              Container(
                padding: EdgeInsets.all(16),
                child: GameForm(
                  formKey: _gameFormKey,
                  game: _gm.game,
                  ruleCallback: (rule) {
                    _gm.game.rule = rule;
                  },
                  winScoreCallback: (score) {
                    _gm.game.winScore = score;
                  },
                ),
              ),
            ])
          : Container(),
      bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).primaryColor,
          child: Container(
            height: 56,
            child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
              FlatButton(
                textColor: Theme.of(context).accentColor,
                child: Text(
                    FlutterI18n.translate(context, 'ui.cancel').toUpperCase()),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Spacer(),
              FlatButton(
                textColor: Colors.green[500],
                child: Text(
                    FlutterI18n.translate(context, 'ui.save').toUpperCase()),
                onPressed: () => _save(),
              ),
            ]),
          )),
    );
  }
}
