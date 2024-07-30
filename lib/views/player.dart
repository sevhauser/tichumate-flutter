import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/state/database.dart';
import 'package:tichumate/state/models.dart';
import 'package:tichumate/dialogs/player.dart';
import 'package:tichumate/utils/playerstatistics.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return _PlayerViewContent(args['playerId']);
  }
}

class _PlayerViewContent extends StatefulWidget {
  final int playerId;
  const _PlayerViewContent(this.playerId) : super();

  @override
  State<_PlayerViewContent> createState() => _PlayerViewContentState();
}

class _PlayerViewContentState extends State<_PlayerViewContent> {
  bool _loaded = false;
  bool _hasPlayer = true;
  late Player _player;
  late PlayerStatistics _statistics;
  int get playerId => widget.playerId;

  _PlayerViewContentState() : super();

  @override
  void initState() {
    super.initState();
    _loadPlayer().whenComplete(() {
      setState(() {
        _loaded = true;
      });
    });
  }

  Future<void> _loadPlayer() async {
    try {
      var player = await TichuDB().players.getFromId(playerId);
      var statistics = PlayerStatistics(playerId);
      await statistics.init();
      setState(() {
        _statistics = statistics;
        _player = player;
      });
    } catch (e) {
      setState(() {
        _hasPlayer = false;
      });
    }
  }

  void _editPlayer() async {
    await PlayerDialog(context).editPlayer(playerId);
    await _loadPlayer();
  }

  void _deletePlayer() async {
    var deleted = await PlayerDialog(context).deletePlayer(playerId);
    if (deleted && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _loaded && _hasPlayer
            ? ListView(
                children: <Widget>[
                  Card(
                      margin: EdgeInsets.zero,
                      color: Theme.of(context).primaryColor,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            Center(
                              child: Text(_player.name,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                            Container(
                                padding: const EdgeInsets.only(top: 4),
                                child: Center(
                                  child: Text(_player.icon),
                                ))
                          ],
                        ),
                      )),
                  _DataRow(
                      FlutterI18n.translate(context, 'game.games')
                          .toUpperCase(),
                      [
                        _DataRowItem(
                            label: FlutterI18n.translate(
                                    context, 'player.statistics.played')
                                .toUpperCase(),
                            value: _statistics.gamesPlayed.toString()),
                        _DataRowItem(
                            label: FlutterI18n.translate(
                                    context, 'player.statistics.won')
                                .toUpperCase(),
                            value: _statistics.gamesWon.toString(),
                            color: Colors.green.shade500),
                        _DataRowItem(
                            label: FlutterI18n.translate(
                                    context, 'player.statistics.lost')
                                .toUpperCase(),
                            value: _statistics.gamesLost.toString(),
                            color: Colors.red.shade500),
                      ]),
                  const Divider(),
                  _DataRow(
                      FlutterI18n.translate(context, 'round.rounds')
                          .toUpperCase(),
                      [
                        _DataRowItem(
                          label: FlutterI18n.translate(
                                  context, 'player.statistics.played')
                              .toUpperCase(),
                          value: _statistics.roundsPlayed.toString(),
                        ),
                        _DataRowItem(
                          label: FlutterI18n.translate(
                                  context, 'player.statistics.won')
                              .toUpperCase(),
                          value: _statistics.roundsWon.toString(),
                          color: Colors.green.shade500,
                        ),
                        _DataRowItem(
                            label: FlutterI18n.translate(
                                    context, 'player.statistics.double_win')
                                .toUpperCase(),
                            value: _statistics.roundsDoubleWon.toString(),
                            color: Colors.amber.shade400),
                        _DataRowItem(
                            label: FlutterI18n.translate(
                                    context, 'player.statistics.lost')
                                .toUpperCase(),
                            value: _statistics.roundsLost.toString(),
                            color: Colors.red.shade500),
                      ]),
                  const Divider(),
                ],
              )
            : Container(),
        bottomNavigationBar: BottomAppBar(
            color: Theme.of(context).primaryColor,
            child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editPlayer(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePlayer(),
                    )
                  ],
                ))));
  }
}

class _DataRow extends StatelessWidget {
  final String title;
  final List<_DataRowItem> items;

  const _DataRow(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(title, style: const TextStyle(fontSize: 18)),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: items
                .map((el) => SizedBox(
                    width: 75,
                    child: Column(
                      children: <Widget>[
                        Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(el.value,
                                style: TextStyle(
                                    fontFamily: 'RobotoSlab',
                                    fontSize: 24,
                                    color: el.color))),
                        Text(el.label),
                      ],
                    )))
                .toList(),
          )
        ],
      ),
    );
  }
}

class _DataRowItem {
  final String label;
  final String value;
  final Color color;

  _DataRowItem({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });
}
