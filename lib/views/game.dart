import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/state/database.dart';
import 'package:tichumate/state/models.dart';
import 'package:tichumate/components/gameheader.dart';
import 'package:tichumate/components/gamecharts.dart';
import 'package:tichumate/utils/gamemanager.dart';
import 'package:tichumate/utils/routing.dart';
import 'package:tichumate/views/round.dart';

class GameViewArguments {
  final int gameId;
  GameViewArguments({required this.gameId});
}

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    final GameViewArguments args =
        ModalRoute.of(context)!.settings.arguments as GameViewArguments;
    return _GameViewContent(gameId: args.gameId);
  }
}

enum _GameOptions { edit, delete }

class _GameViewContent extends StatefulWidget {
  final int gameId;

  const _GameViewContent({
    required this.gameId,
  });

  @override
  _GameViewContentState createState() => _GameViewContentState();
}

class _GameViewContentState extends State<_GameViewContent> with RouteAware {
  late int _gameId;
  late GameManager _gm;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _gameId = widget.gameId;
    _loadGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      _loaded = false;
    });
    _loadGame();
  }

  void _loadGame() async {
    _gm = GameManager(gameId: _gameId);
    await _gm.init();
    setState(() {
      _loaded = true;
    });
  }

  void _newRound() {
    Navigator.of(context)
        .pushNamed('/round', arguments: RoundViewArguments(gameId: _gameId));
  }

  void _removeRound(int roundId) async {
    await _gm.removeRound(roundId);
    setState(() {
      _loaded = true;
    });
  }

  void _editGame() async {
    Navigator.of(context).pushNamed('/editgame',
        arguments: GameViewArguments(gameId: _gm.gameId));
  }

  void _deleteGame() async {
    var result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(FlutterI18n.translate(context, 'game.delete_game')),
        actions: <Widget>[
          TextButton(
            child:
                Text(FlutterI18n.translate(context, 'ui.cancel').toUpperCase()),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text(
                FlutterI18n.translate(context, 'ui.delete').toUpperCase(),
                style: TextStyle(color: Colors.red.shade500)),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    if (result != null && result) {
      await _gm.delete();
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  void _close() async {
    Navigator.of(context).pop();
  }

  void _statistics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GameStatistics(
        gameManager: _gm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loaded
        ? Scaffold(
            body: Column(
              children: <Widget>[
                GameHeader(
                  slots: <GameHeaderSlot>[
                    GameHeaderSlot(
                        players: _gm.team1.players,
                        score: _gm.team1.score,
                        teamName: _gm.team1.name,
                        status: _gm.team1Status,
                        difference: _gm.team1Difference),
                    GameHeaderSlot(
                        players: _gm.team2.players,
                        score: _gm.team2.score,
                        teamName: _gm.team2.name,
                        status: _gm.team2Status,
                        difference: _gm.team2Difference)
                  ],
                  showDifference: true,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                    ),
                    itemCount: _gm.rounds.length,
                    itemBuilder: (context, index) => _RoundListTile(
                      key: UniqueKey(),
                      onDelete: () => _removeRound(_gm.rounds[index].id!),
                      onEdit: () {
                        Navigator.of(context).pushNamed('/round',
                            arguments: RoundViewArguments(
                                gameId: _gameId,
                                roundId: _gm.rounds[index].id!));
                      },
                      confirmDelete: () async {
                        return true;
                      },
                      round: _gm.rounds[index],
                      roundNumber: index + 1,
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: FloatingActionButton(
              onPressed: () => _newRound(),
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            ),
            bottomNavigationBar: BottomAppBar(
                color: Theme.of(context).primaryColor,
                shape: const CircularNotchedRectangle(),
                notchMargin: 10,
                height: 64,
                child: SizedBox(
                    child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _close(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.trending_up),
                      onPressed: () => _statistics(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: PopupMenuButton(
                        child: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == _GameOptions.edit) {
                            _editGame();
                          } else if (value == _GameOptions.delete) {
                            _deleteGame();
                          }
                        },
                        itemBuilder: (context) =>
                            <PopupMenuEntry<_GameOptions>>[
                          PopupMenuItem(
                            value: _GameOptions.edit,
                            child: Text(FlutterI18n.translate(
                                context, 'game.edit_game')),
                          ),
                          PopupMenuItem(
                              value: _GameOptions.delete,
                              child: Text(
                                  FlutterI18n.translate(
                                      context, 'game.delete_game'),
                                  style: TextStyle(color: Colors.red.shade500)))
                        ],
                      ),
                    )
                  ],
                ))))
        : Container();
  }
}

typedef _RoundListTileConfirmation = Future<bool> Function();
typedef _RoundListTileAction = void Function();

class _RoundListTile extends StatelessWidget {
  static const _edit = DismissDirection.endToStart,
      _delete = DismissDirection.startToEnd;
  final _RoundListTileConfirmation confirmDelete;
  final _RoundListTileAction onDelete, onEdit;
  final Round round;
  final int roundNumber;

  const _RoundListTile({
    required super.key,
    required this.confirmDelete,
    required this.onDelete,
    required this.onEdit,
    required this.round,
    required this.roundNumber,
  });
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: super.key!,
      confirmDismiss: (direction) {
        if (direction == _edit) {
          onEdit();
        } else if (direction == DismissDirection.startToEnd) {
          return confirmDelete();
        }
        return Future.value(false);
      },
      onDismissed: (direction) {
        if (direction == _edit) {
          onEdit();
        } else if (direction == _delete) {
          onDelete();
        }
      },
      background: Container(
        padding: const EdgeInsets.only(left: 16),
        color: Colors.red.shade500,
        child: const Align(
            alignment: Alignment.centerLeft, child: Icon(Icons.cancel)),
      ),
      secondaryBackground: Container(
        padding: const EdgeInsets.only(right: 16),
        color: Colors.green.shade500,
        child: const Align(
            alignment: Alignment.centerRight, child: Icon(Icons.edit)),
      ),
      child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: _ScoreSummary(
                  score: round.scores.values.first,
                ),
              ),
              Text(
                roundNumber.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              Expanded(
                child: _ScoreSummary(
                  score: round.scores.values.last,
                  reversed: true,
                ),
              )
            ],
          )),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  final Score score;
  final bool reversed;

  const _ScoreSummary({
    required this.score,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    var win = '';
    switch (score.win) {
      case 1:
        win = FlutterI18n.translate(context, 'game.score.win_short');
        break;
      case 2:
        win = FlutterI18n.translate(context, 'game.score.double_win_short');
        break;
    }
    var winColumn = Text(
      win,
      style: TextStyle(fontSize: 20, color: Colors.amber.shade400),
    );
    var callsColumn = <Widget>[];
    for (var call in score.calls) {
      var tichu = TichuDB().tichus.getFromCache(call.tichuId!)!;
      var title = tichu.lang.isEmpty
          ? tichu.short
          : FlutterI18n.translate(context, '${tichu.lang}.short');
      callsColumn.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(title,
            style: TextStyle(
                fontSize: 20,
                color: call.success
                    ? Colors.green.shade500
                    : Colors.red.shade500)),
      ));
    }

    var content = <Widget>[
      Expanded(child: Center(child: winColumn)),
      Text(score.score.toString(),
          style: const TextStyle(fontFamily: 'RobotoSlab', fontSize: 20)),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: callsColumn,
        ),
      )
    ];

    return Flex(
      direction: Axis.horizontal,
      children: reversed ? content : content.reversed.toList(),
    );
  }
}
