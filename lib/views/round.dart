import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/components/gameheader.dart';
import 'package:tichumate/database.dart';
import 'package:tichumate/models.dart';
import 'package:tichumate/utils/gamemanager.dart';

class RoundViewArguments {
  int gameId;
  int roundId;
  RoundViewArguments({
    @required this.gameId,
    this.roundId,
  });
}

class RoundView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    RoundViewArguments args = ModalRoute.of(context).settings.arguments;
    return _RoundViewContent(
      gameId: args.gameId,
      roundId: args.roundId,
    );
  }
}

class _RoundViewContent extends StatefulWidget {
  final int gameId, roundId;

  _RoundViewContent({@required this.gameId, this.roundId, Key key})
      : super(key: key);

  @override
  _RoundViewContentState createState() => _RoundViewContentState();
}

class _RoundViewContentState extends State<_RoundViewContent> {
  int _gameId, _roundId;
  bool _loaded = false, _hasChanged = false;
  GameManager _gm;
  RoundManager _m;

  @override
  void initState() {
    super.initState();
    _gameId = widget.gameId;
    _roundId = widget.roundId;
    _loadRound();
  }

  Future<void> _loadRound() async {
    _gm = GameManager(gameId: _gameId);
    await _gm.init();
    _m = _gm.roundManager(roundId: _roundId);
    setState(() {
      _loaded = true;
    });
  }

  void _save() async {
    if (!_m.hasWinner) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(
                    FlutterI18n.translate(context, 'ui.errors.missing_input')),
                content: Text(FlutterI18n.translate(
                    context, 'round.please_select_a_winner')),
                actions: <Widget>[
                  FlatButton(
                    child: Text(
                        FlutterI18n.translate(context, 'ui.ok').toUpperCase()),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ));
      return;
    }
    await _m.save();
    Navigator.of(context).pop();
  }

  Future<void> _closeDialog() async {
    if (await _close()) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _close() async {
    if (!_hasChanged) {
      return true;
    }
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave?'),
        actions: <Widget>[
          FlatButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          FlatButton(
            child: Text(
              'Yes',
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _tichus(BuildContext context) {
    var result = <Widget>[];
    TichuDB().tichus.cachedTichus.forEach((tichu) {
      var title = tichu.lang.isEmpty
          ? tichu.title
          : FlutterI18n.translate(context, tichu.lang + '.title');
      result.add(Divider(height: 1));
      result.add(_TichuInputRow(
        label: title.toUpperCase(),
        children: <Widget>[
          _TichuToggleButton(
            active: _m.team1CallInfo(tichu.id, true) != null,
            label:
                FlutterI18n.translate(context, 'round.success').toUpperCase(),
            onPressed: () => setState(() {
              _m.teamCall(
                  _m.score1,
                  Call.fromValues(
                    tichu: tichu,
                    scoreId: _m.score1.id,
                    success: true,
                  ));
            }),
            type: _TichuToggleButtonType.good,
          ),
          _TichuToggleButton(
            active: _m.team1CallInfo(tichu.id, false) != null,
            label: FlutterI18n.translate(context, 'round.fail').toUpperCase(),
            onPressed: () => setState(() {
              _m.teamCall(
                  _m.score1,
                  Call.fromValues(
                    tichu: tichu,
                    scoreId: _m.score1.id,
                    success: false,
                  ));
            }),
            type: _TichuToggleButtonType.bad,
          ),
          _TichuToggleButton(
            active: _m.team2CallInfo(tichu.id, false) != null,
            label: FlutterI18n.translate(context, 'round.fail').toUpperCase(),
            onPressed: () => setState(() {
              _m.teamCall(
                  _m.score2,
                  Call.fromValues(
                    tichu: tichu,
                    scoreId: _m.score2.id,
                    success: false,
                  ));
            }),
            type: _TichuToggleButtonType.bad,
          ),
          _TichuToggleButton(
            active: _m.team2CallInfo(tichu.id, true) != null,
            label:
                FlutterI18n.translate(context, 'round.success').toUpperCase(),
            onPressed: () => setState(() {
              _m.teamCall(
                  _m.score2,
                  Call.fromValues(
                    tichu: tichu,
                    scoreId: _m.score2.id,
                    success: true,
                  ));
            }),
            type: _TichuToggleButtonType.good,
          ),
        ],
      ));
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () => _close(),
        child: _loaded
            ? Scaffold(
                body: Column(
                  children: <Widget>[
                    GameHeader(
                      slots: <GameHeaderSlot>[
                        GameHeaderSlot(
                            players: _m.team1.players,
                            score: _m.score1.score,
                            status: _m.score1Status,
                            teamName: _m.team1.name),
                        GameHeaderSlot(
                            players: _m.team2.players,
                            score: _m.score2.score,
                            status: _m.score2Status,
                            teamName: _m.team2.name),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(bottom: 28),
                        children: <Widget>[
                          _TichuInputRow(
                            label: FlutterI18n.translate(
                                    context, 'round.card_points')
                                .toUpperCase(),
                            children: <Widget>[
                              Expanded(
                                  child: Container(
                                margin: EdgeInsets.only(top: 12),
                                child: SliderTheme(
                                  key: UniqueKey(),
                                  data: SliderTheme.of(context).copyWith(
                                    thumbColor: Theme.of(context).accentColor,
                                    activeTrackColor: Colors.grey[700],
                                    inactiveTrackColor: Colors.grey[700],
                                    inactiveTickMarkColor: Colors.transparent,
                                    activeTickMarkColor: Colors.transparent,
                                    disabledActiveTickMarkColor:
                                        Colors.transparent,
                                    disabledInactiveTickMarkColor:
                                        Colors.transparent,
                                  ),
                                  child: Slider(
                                    value:
                                        (_m.scoreDistribution.toDouble() / 10),
                                    min: -7.5,
                                    max: 7.5,
                                    divisions: 30,
                                    onChanged: _m.hasDoubleWin
                                        ? null
                                        : (double value) {
                                            _m.scoreDistribution =
                                                (value * 10).toInt();
                                            setState(() {});
                                          },
                                  ),
                                ),
                              )),
                            ],
                          ),
                          Divider(height: 1),
                          _TichuInputRow(
                            label:
                                FlutterI18n.translate(context, 'round.winner')
                                    .toUpperCase(),
                            children: <Widget>[
                              _TichuWinButton(
                                label: FlutterI18n.translate(
                                        context, 'round.double')
                                    .toUpperCase(),
                                onPressed: () => setState(() {
                                  _m.win1(doubleWin: true);
                                }),
                                active: _m.score1.win == 2,
                              ),
                              _TichuWinButton(
                                label:
                                    FlutterI18n.translate(context, 'round.win')
                                        .toUpperCase(),
                                onPressed: () => setState(() {
                                  _m.win1();
                                }),
                                active: _m.score1.win > 0,
                              ),
                              _TichuWinButton(
                                label:
                                    FlutterI18n.translate(context, 'round.win')
                                        .toUpperCase(),
                                onPressed: () => setState(() {
                                  _m.win2();
                                }),
                                active: _m.score2.win > 0,
                              ),
                              _TichuWinButton(
                                label: FlutterI18n.translate(
                                        context, 'round.double')
                                    .toUpperCase(),
                                onPressed: () => setState(() {
                                  _m.win2(doubleWin: true);
                                }),
                                active: _m.score2.win == 2,
                              ),
                            ],
                          ),
                          ..._tichus(context)
                        ],
                      ),
                    )
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => _save(),
                  child: Icon(Icons.check),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: BottomAppBar(
                    color: Theme.of(context).primaryColor,
                    shape: CircularNotchedRectangle(),
                    notchMargin: 10,
                    child: Container(
                        height: 56,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.arrow_back),
                              onPressed: () => _closeDialog(),
                            ),
                          ],
                        ))),
              )
            : Container());
  }
}

typedef _TichuButtonCallback = void Function();

class _TichuWinButton extends StatelessWidget {
  final bool active;
  final String label;
  final _TichuButtonCallback onPressed;

  _TichuWinButton({
    @required this.active,
    @required this.label,
    @required this.onPressed,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _TichuButton(
      active: active,
      label: label,
      onPressed: onPressed,
      activeColor: Theme.of(context).accentColor,
    );
  }
}

enum _TichuToggleButtonType { good, bad }

class _TichuToggleButton extends StatelessWidget {
  final String label;
  final bool active;
  final _TichuButtonCallback onPressed;
  final _TichuToggleButtonType type;

  _TichuToggleButton({
    @required this.label,
    @required this.active,
    @required this.onPressed,
    @required this.type,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var activeColor;
    switch (type) {
      case _TichuToggleButtonType.bad:
        activeColor = Colors.red[500];
        break;
      case _TichuToggleButtonType.good:
        activeColor = Colors.green[500];
        break;
    }
    return _TichuButton(
      active: active,
      label: label,
      onPressed: onPressed,
      activeColor: activeColor,
    );
  }
}

class _TichuButton extends StatelessWidget {
  final bool active;
  final Color activeColor;
  final _TichuButtonCallback onPressed;
  final String label;
  _TichuButton({
    @required this.active,
    @required this.activeColor,
    @required this.onPressed,
    @required this.label,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: Text(label,
          style: TextStyle(
              color: active ? activeColor : Colors.grey[500], fontSize: 15)),
      onPressed: () => onPressed(),
    );
  }
}

class _TichuInputRow extends StatelessWidget {
  final List<Widget> children;
  final String label;

  _TichuInputRow({@required this.children, @required this.label, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(bottom: 12, top: 18),
        child: Column(children: <Widget>[
          Container(
              child: Center(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          )),
          Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children
                .map((child) => Container(
                      child: child,
                    ))
                .toList(),
          ),
        ]));
  }
}
