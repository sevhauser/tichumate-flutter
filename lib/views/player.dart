import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/database.dart';
import 'package:tichumate/models.dart';
import 'package:tichumate/dialogs/player.dart';
import 'package:tichumate/utils/playerstatistics.dart';

class PlayerView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context).settings.arguments;
    return _PlayerViewContent(args['playerId']);
  }
}

class _PlayerViewContent extends StatefulWidget {
  final int playerId;
  _PlayerViewContent(this.playerId) : super();

  @override
  _PlayerViewContentState createState() => _PlayerViewContentState(playerId);
}

class _PlayerViewContentState extends State<_PlayerViewContent> {
  final int playerId;
  bool _loaded = false;
  bool _hasPlayer = true;
  Player _player;
  PlayerStatistics _statistics;

  _PlayerViewContentState(this.playerId) : super();

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
    if (deleted) {
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      child: Container(
                        margin: EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            Center(
                              child: Text(_player.name,
                                  style: TextStyle(fontSize: 20)),
                            ),
                            Container(
                                padding: EdgeInsets.only(top: 4),
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
                            color: Colors.green[500]),
                        _DataRowItem(
                            label: FlutterI18n.translate(
                                    context, 'player.statistics.lost')
                                .toUpperCase(),
                            value: _statistics.gamesLost.toString(),
                            color: Colors.red[500]),
                      ]),
                  Divider(),
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
                          color: Colors.green[500],
                        ),
                        _DataRowItem(
                            label: FlutterI18n.translate(
                                    context, 'player.statistics.double_win')
                                .toUpperCase(),
                            value: _statistics.roundsDoubleWon.toString(),
                            color: Theme.of(context).accentColor),
                        _DataRowItem(
                            label: FlutterI18n.translate(
                                    context, 'player.statistics.lost')
                                .toUpperCase(),
                            value: _statistics.roundsLost.toString(),
                            color: Colors.red[500]),
                      ]),
                  Divider(),
                ],
              )
            : Container(),
        bottomNavigationBar: BottomAppBar(
            color: Theme.of(context).primaryColor,
            child: Container(
                height: 56,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editPlayer(),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deletePlayer(),
                    )
                  ],
                ))));
  }
}

class _DataRow extends StatelessWidget {
  final String title;
  final List<_DataRowItem> items;

  _DataRow(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(title, style: TextStyle(fontSize: 18)),
          ),
          Container(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: items
                  .map((el) => Container(
                      width: 75,
                      child: Column(
                        children: <Widget>[
                          Container(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(el.value,
                                  style: TextStyle(
                                      fontFamily: 'RobotoSlab',
                                      fontSize: 24,
                                      color: el.color))),
                          Container(
                            child: Text(el.label),
                          ),
                        ],
                      )))
                  .toList(),
            ),
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
    @required this.label,
    @required this.value,
    this.color: Colors.white,
  });
}
