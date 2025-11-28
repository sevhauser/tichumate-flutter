import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/components/gameheader.dart';
import 'package:tichumate/state/database.dart';
import 'package:tichumate/state/models.dart';
import 'package:tichumate/utils/gamemanager.dart';

class RoundViewArguments {
  int gameId;
  int? roundId;
  RoundViewArguments({
    required this.gameId,
    this.roundId,
  });
}

class RoundView extends StatelessWidget {
  const RoundView({super.key});

  @override
  Widget build(BuildContext context) {
    RoundViewArguments args =
        ModalRoute.of(context)!.settings.arguments as RoundViewArguments;
    return _RoundViewContent(
      gameId: args.gameId,
      roundId: args.roundId,
    );
  }
}

class _RoundViewContent extends StatefulWidget {
  final int gameId;
  final int? roundId;

  const _RoundViewContent({required this.gameId, this.roundId});

  @override
  _RoundViewContentState createState() => _RoundViewContentState();
}

class _RoundViewContentState extends State<_RoundViewContent> {
  late int _gameId;
  int? _roundId;
  bool _loaded = false;
  late GameManager _gm;
  late RoundManager _m;

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
                  TextButton(
                    child: Text(
                        FlutterI18n.translate(context, 'ui.ok').toUpperCase()),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ));
      return;
    }
    await _m.save();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _closeDialog() async {
    var close = await _close();
    if (close != null && close && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _close() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(FlutterI18n.translate(context, 'round.leave')),
        actions: <Widget>[
          TextButton(
            child: Text(FlutterI18n.translate(context, 'ui.cancel')),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text(FlutterI18n.translate(context, 'ui.yes')),
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
    for (var tichu in TichuDB().tichus.cachedTichus) {
      var title = tichu.lang.isEmpty
          ? tichu.title
          : FlutterI18n.translate(context, '${tichu.lang}.title');
      result.add(const Divider(height: 1));
      result.add(_TichuInputRow(
        label: title.toUpperCase(),
        children: <Widget>[
          _TichuToggleButton(
            active: _m.team1CallInfo(tichu.id!, true) != null,
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
            active: _m.team1CallInfo(tichu.id!, false) != null,
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
            active: _m.team2CallInfo(tichu.id!, false) != null,
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
            active: _m.team2CallInfo(tichu.id!, true) != null,
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
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _closeDialog();
        },
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
                        padding: const EdgeInsets.only(bottom: 28),
                        children: <Widget>[
                          _TichuInputRow(
                            label: FlutterI18n.translate(
                                    context, 'round.card_points')
                                .toUpperCase(),
                            children: <Widget>[
                              Expanded(
                                  child: Container(
                                margin: const EdgeInsets.only(top: 12),
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbColor: Colors.amber.shade400,
                                    activeTrackColor: Colors.grey.shade700,
                                    inactiveTrackColor: Colors.grey.shade700,
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
                                    onChanged: (double value) {
                                      if (_m.hasDoubleWin) {
                                        return;
                                      }
                                      setState(() {
                                        _m.scoreDistribution =
                                            (value * 10).toInt();
                                      });
                                    },
                                  ),
                                ),
                              )),
                            ],
                          ),
                          const Divider(height: 1),
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
                  shape: const CircleBorder(),
                  child: const Icon(Icons.check),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: BottomAppBar(
                    color: Theme.of(context).primaryColor,
                    shape: const CircularNotchedRectangle(),
                    notchMargin: 10,
                    child: SizedBox(
                        height: 56,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
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

  const _TichuWinButton({
    required this.active,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _TichuButton(
      active: active,
      label: label,
      onPressed: onPressed,
      activeColor: Colors.amber.shade300,
    );
  }
}

enum _TichuToggleButtonType { good, bad }

class _TichuToggleButton extends StatelessWidget {
  final String label;
  final bool active;
  final _TichuButtonCallback onPressed;
  final _TichuToggleButtonType type;

  const _TichuToggleButton({
    required this.label,
    required this.active,
    required this.onPressed,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    var activeColor = Colors.white;
    switch (type) {
      case _TichuToggleButtonType.bad:
        activeColor = Colors.red.shade500;
        break;
      case _TichuToggleButtonType.good:
        activeColor = Colors.green.shade500;
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
  const _TichuButton({
    required this.active,
    required this.activeColor,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(label,
          style: TextStyle(
              color: active ? activeColor : Colors.grey.shade500,
              fontSize: 15)),
      onPressed: () => onPressed(),
    );
  }
}

class _TichuInputRow extends StatelessWidget {
  final List<Widget> children;
  final String label;

  const _TichuInputRow({required this.children, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 12, top: 18),
        child: Column(children: <Widget>[
          Center(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
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
