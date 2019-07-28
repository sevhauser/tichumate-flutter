import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/components/gameform.dart';
import 'package:tichumate/database.dart';
import 'package:tichumate/models.dart';
import 'package:tichumate/components/teamform.dart';
import 'package:tichumate/views/game.dart';

class NewGameView extends StatefulWidget {
  @override
  _NewGameViewState createState() => _NewGameViewState();
}

class _NewGameViewState extends State<NewGameView> {
  final int _lastStep = 2;
  int _currentStep = 0;
  Game _game = Game();
  Team _team1 = Team();
  Team _team2 = Team();
  final _team1FormKey = GlobalKey<FormState>(),
      _team2FormKey = GlobalKey<FormState>(),
      _gameFormKey = GlobalKey<FormState>();

  Future<bool> _cancelDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(FlutterI18n.translate(context, 'game.quit_new_game')),
        actions: <Widget>[
          FlatButton(
            child:
                Text(FlutterI18n.translate(context, 'ui.cancel').toUpperCase()),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          FlatButton(
            child: Text(
              FlutterI18n.translate(context, 'ui.ok').toUpperCase(),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  void _cancel() async {
    if (await _cancelDialog()) {
      Navigator.of(context).pop();
    }
  }

  bool _saveCurrentForm() {
    if (_currentStep == 0) {
      final form = _team1FormKey.currentState;
      form.save();
    } else if (_currentStep == 1) {
      final form = _team2FormKey.currentState;
      form.save();
    } else if (_currentStep == 2) {
      final form = _gameFormKey.currentState;
      if (form.validate()) {
        form.save();
        return true;
      }
      return false;
    }
    return true;
  }

  void _setStep(int index) {
    if (index >= 0 && index <= _lastStep) {
      if (!_saveCurrentForm()) return;
      setState(() {
        _currentStep = index;
      });
    }
  }

  void _createGame() async {
    if (!_saveCurrentForm()) return;
    var newGame = await TichuDB().games.create(_game, _team1, _team2);
    Navigator.of(context).pushReplacementNamed('/game',
        arguments: GameViewArguments(gameId: newGame.id));
  }

  void _nextStep() {
    if (_currentStep == _lastStep) return;
    if (!_saveCurrentForm()) return;
    setState(() {
      _currentStep += 1;
    });
  }

  void _prevStep() {
    if (_currentStep == 0) return;
    if (!_saveCurrentForm()) return;
    setState(() {
      _currentStep -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () => _cancelDialog(),
        child: Scaffold(
            body: Container(
                margin: EdgeInsets.only(top: 24),
                child: Stepper(
                  currentStep: _currentStep,
                  type: StepperType.horizontal,
                  steps: <Step>[
                    Step(
                      isActive: _currentStep == 0,
                      title: Text(
                          FlutterI18n.translate(context, 'team.team') + ' 1'),
                      content: TeamForm(
                        formKey: _team1FormKey,
                        team: _team1,
                        teamNameCallback: (name) => _team1.name = name,
                        playersCallback: (players) {
                          _team1.players = players;
                        },
                        secondaryPlayers: _team2.players,
                      ),
                    ),
                    Step(
                        isActive: _currentStep == 1,
                        title: Text(
                            FlutterI18n.translate(context, 'team.team') + ' 2'),
                        content: TeamForm(
                          formKey: _team2FormKey,
                          team: _team2,
                          teamNameCallback: (name) => _team2.name = name,
                          playersCallback: (players) =>
                              _team2.players = players,
                          secondaryPlayers: _team1.players,
                        )),
                    Step(
                      isActive: _currentStep == 2,
                      title: Text(
                          FlutterI18n.translate(context, 'game.rules.rules')),
                      content: Container(
                          padding: EdgeInsets.only(bottom: 16),
                          child: GameForm(
                            game: _game,
                            formKey: _gameFormKey,
                            ruleCallback: (rule) => _game.rule = rule,
                            winScoreCallback: (score) => _game.winScore = score,
                          )),
                    ),
                  ],
                  onStepCancel: () => _prevStep(),
                  onStepContinue: () => _nextStep(),
                  onStepTapped: _setStep,
                  controlsBuilder: (context,
                          {VoidCallback onStepContinue,
                          VoidCallback onStepCancel}) =>
                      Container(),
                )),
            bottomNavigationBar: BottomAppBar(
                color: Theme.of(context).primaryColor,
                child: Container(
                  height: 56,
                  child: Row(
                    children: <Widget>[
                      _currentStep == 0
                          ? FlatButton(
                              child: Text(
                                  FlutterI18n.translate(context, 'ui.cancel')
                                      .toUpperCase(),
                                  style: TextStyle(
                                      color: Theme.of(context).accentColor)),
                              onPressed: () => _cancel(),
                            )
                          : FlatButton(
                              child: Text(
                                  FlutterI18n.translate(context, 'ui.back')
                                      .toUpperCase(),
                                  style: TextStyle(
                                      color: Theme.of(context).accentColor)),
                              onPressed: () => _prevStep(),
                            ),
                      Spacer(),
                      _currentStep < _lastStep
                          ? FlatButton(
                              child: Text(
                                  FlutterI18n.translate(context, 'ui.next')
                                      .toUpperCase(),
                                  style: TextStyle(
                                      color: Theme.of(context).accentColor)),
                              onPressed: () => _nextStep(),
                            )
                          : FlatButton(
                              child: Text(
                                  FlutterI18n.translate(
                                          context, 'game.start_game')
                                      .toUpperCase(),
                                  style: TextStyle(color: Colors.green[500])),
                              onPressed: () => _createGame(),
                            ),
                    ],
                  ),
                ))));
  }
}
