import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/main.dart';
import 'package:tichumate/database.dart';
import 'package:tichumate/models.dart';
import 'package:tichumate/components/gameheader.dart';
import 'package:tichumate/utils/gamemanager.dart';
import 'package:tichumate/views/round.dart';

class GameViewArguments {
  final int gameId;
  GameViewArguments({@required this.gameId});
}

class GameView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final GameViewArguments args = ModalRoute.of(context).settings.arguments;
    return _GameViewContent(gameId: args.gameId);
  }
}

enum _GameOptions { edit, delete }

class _GameViewContent extends StatefulWidget {
  final int gameId;
  _GameViewContent({
    @required this.gameId,
    Key key,
  }) : super(key: key);

  @override
  _GameViewContentState createState() => _GameViewContentState();
}

class _GameViewContentState extends State<_GameViewContent> with RouteAware {
  int _gameId;
  GameManager _gm;
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
    routeObserver.subscribe(this, ModalRoute.of(context));
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
          FlatButton(
            child:
                Text(FlutterI18n.translate(context, 'ui.cancel').toUpperCase()),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          FlatButton(
            child: Text(
                FlutterI18n.translate(context, 'ui.delete').toUpperCase(),
                style: TextStyle(color: Colors.red[500])),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    if (result != null && result) {
      await _gm.delete();
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
      builder: (context) => _GameStatistics(
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
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 28),
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                    ),
                    itemCount: _gm.rounds.length,
                    itemBuilder: (context, index) => _RoundListTile(
                      key: UniqueKey(),
                      onDelete: () => _removeRound(_gm.rounds[index].id),
                      onEdit: () {
                        Navigator.of(context).pushNamed('/round',
                            arguments: RoundViewArguments(
                                gameId: _gameId,
                                roundId: _gm.rounds[index].id));
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
              child: Icon(Icons.add),
              onPressed: () => _newRound(),
            ),
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
                          onPressed: () => _close(),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.trending_up),
                          onPressed: () => _statistics(),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: PopupMenuButton(
                            child: Icon(Icons.more_vert),
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
                                child: Text(FlutterI18n.translate(
                                    context, 'game.edit_game')),
                                value: _GameOptions.edit,
                              ),
                              PopupMenuItem(
                                  value: _GameOptions.delete,
                                  child: Text(
                                      FlutterI18n.translate(
                                          context, 'game.delete_game'),
                                      style: TextStyle(color: Colors.red[500])))
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
  final Key key;
  final _RoundListTileConfirmation confirmDelete;
  final _RoundListTileAction onDelete, onEdit;
  final Round round;
  final int roundNumber;

  _RoundListTile({
    @required this.key,
    @required this.confirmDelete,
    @required this.onDelete,
    @required this.onEdit,
    @required this.round,
    @required this.roundNumber,
  });
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key,
      confirmDismiss: (direction) {
        if (direction == _edit) {
          this.onEdit();
        } else if (direction == DismissDirection.startToEnd) {
          return this.confirmDelete();
        }
        return Future.value(false);
      },
      onDismissed: (direction) {
        if (direction == _edit) {
          this.onEdit();
        } else if (direction == _delete) {
          this.onDelete();
        }
      },
      child: Container(
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: 16),
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
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              Expanded(
                child: _ScoreSummary(
                  score: round.scores.values.last,
                  reversed: true,
                ),
              )
            ],
          )),
      background: Container(
        padding: EdgeInsets.only(left: 16),
        color: Colors.red[500],
        child:
            Align(alignment: Alignment.centerLeft, child: Icon(Icons.cancel)),
      ),
      secondaryBackground: Container(
        padding: EdgeInsets.only(right: 16),
        color: Colors.green[500],
        child: Align(alignment: Alignment.centerRight, child: Icon(Icons.edit)),
      ),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  final Score score;
  final bool reversed;

  _ScoreSummary({
    @required this.score,
    this.reversed: false,
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
    var winColumn = Container(
        child: Text(
      win,
      style: TextStyle(fontSize: 20, color: Theme.of(context).accentColor),
    ));
    var callsColumn = <Widget>[];
    score.calls.forEach((call) {
      var tichu = TichuDB().tichus.getFromCache(call.tichuId);
      var title = tichu.lang.isEmpty
          ? tichu.short
          : FlutterI18n.translate(context, tichu.lang + '.short');
      callsColumn.add(Container(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text(title,
            style: TextStyle(
                fontSize: 20,
                color: call.success ? Colors.green[500] : Colors.red[500])),
      ));
    });

    var content = <Widget>[
      Expanded(child: Center(child: winColumn)),
      Text(score.score.toString(),
          style: TextStyle(fontFamily: 'RobotoSlab', fontSize: 20)),
      Expanded(
        child: Row(
          children: callsColumn,
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      )
    ];

    return Flex(
      direction: Axis.horizontal,
      children: reversed ? content : content.reversed.toList(),
    );
  }
}

class _GameStatistics extends StatefulWidget {
  final GameManager gameManager;

  _GameStatistics({
    @required this.gameManager,
    Key key,
  }) : super(key: key);

  @override
  _GameStatisticsState createState() => _GameStatisticsState();
}

class _GameStatisticsState extends State<_GameStatistics> {
  GameManager get _m => widget.gameManager;
  GameStatisticsProvider _sp;
  @override
  void initState() {
    super.initState();
    _sp = _m.statistics();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.transparent,
        margin: EdgeInsets.only(top: 24),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
                FlutterI18n.translate(context, 'game.statistics.statistics')),
          ),
          body: ListView(
            shrinkWrap: true,
            children: <Widget>[
              _ScoreChartCard(statisticsProvider: _sp),
              Divider(),
            ],
          ),
        ));
  }
}

class _ScoreChartCard extends StatelessWidget {
  final GameStatisticsProvider statisticsProvider;
  _ScoreChartCard({
    @required this.statisticsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            FlutterI18n.translate(context, 'game.statistics.score_total'),
            style: TextStyle(fontSize: 16),
          ),
        ),
        _ScoreChart(
          statistics: [
            statisticsProvider.statistics.values.first,
            statisticsProvider.statistics.values.last,
          ],
          team1Color: Colors.tealAccent[400],
          team2Color: Colors.red[500],
        ),
      ],
    );
  }
}

class _ScoreChart extends StatefulWidget {
  final List<TeamStatistics> statistics;
  final Color team1Color, team2Color;
  final int winScore;
  _ScoreChart(
      {@required this.statistics,
      @required this.team1Color,
      @required this.team2Color,
      this.winScore});

  @override
  __ScoreChartState createState() => __ScoreChartState();
}

class __ScoreChartState extends State<_ScoreChart> {
  int _selectedIndex = 0;

  String get team1Name {
    if (widget.statistics[0].team.name.isEmpty) {
      return FlutterI18n.translate(context, 'team.team') + ' 1';
    }
    return widget.statistics[0].team.name;
  }

  String get team2Name {
    if (widget.statistics[1].team.name.isEmpty) {
      return FlutterI18n.translate(context, 'team.team') + ' 2';
    }
    return widget.statistics[1].team.name;
  }

  void _onChanged(charts.SelectionModel model) {
    int index = 0;
    if (model.selectedDatum.isNotEmpty) {
      index = model.selectedDatum.first.index;
    }
    try {
      setState(() {
        _selectedIndex = index;
      });
    } catch (e) {}
  }

  List<charts.TickSpec<int>> _staticTicks() {
    var result = <charts.TickSpec<int>>[];
    var maxScore = widget.winScore ?? 0;
    var minScore = 0;
    widget.statistics.forEach((s) {
      maxScore = s.maxScore > maxScore ? s.maxScore : maxScore;
      minScore = s.minScore < minScore ? s.minScore : minScore;
    });
    maxScore = (maxScore / 100).ceil() * 100;
    minScore = (minScore.abs() / 100).ceil() * -100;
    for (var i = minScore; i <= maxScore; i += 100) {
      result.add(charts.TickSpec(i));
    }
    return result;
  }

  Widget _teamColumn(RoundScoreData data, String teamName, Color teamColor) {
    var rows = <Widget>[
      Container(
          height: 16,
          child: Center(
              child: Icon(
            Icons.brightness_1,
            color: teamColor,
            size: 12,
          ))),
      Container(
          height: 24,
          child: Center(
            child: Text(
              teamName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16),
            ),
          )),
    ];
    rows.add(Container(
        height: 32,
        child: Center(
            child: Text(
          data.accumulatedScore.toString(),
          style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 24,
              color: data.win ? Theme.of(context).accentColor : Colors.white),
        ))));
    Color scoreColor;
    if (data.score > 0) {
      scoreColor = Colors.green[300];
    } else if (data.score < 0) {
      scoreColor = Colors.red[300];
    } else {
      scoreColor = Colors.white;
    }
    rows.add(Container(
        height: 24,
        child: Center(
            child: Text(data.score.toString(),
                style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 18,
                    color: scoreColor)))));
    var calls = data.calls.map((c) {
      var tichu = TichuDB().tichus.getFromCache(c.tichuId);
      var title = tichu.lang.isEmpty
          ? tichu.short
          : FlutterI18n.translate(context, tichu.lang + '.short');
      return Container(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(title,
              style: TextStyle(
                  color: c.success ? Colors.green[500] : Colors.red[500],
                  fontSize: 16)));
    }).toList();
    rows.add(Container(
        height: 24,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: calls.isEmpty
                ? [
                    Container(
                      child: Text('', style: const TextStyle(fontSize: 16)),
                    )
                  ]
                : calls)));
    return Column(
      children: rows,
    );
  }

  Widget _selectionLegend() {
    var team1Round = widget.statistics[0].rounds[_selectedIndex];
    var team2Round = widget.statistics[1].rounds[_selectedIndex];
    const legendStyle = const TextStyle(color: Colors.white54);
    return Flex(
      direction: Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
            flex: 2,
            child: _teamColumn(team1Round, team1Name, widget.team1Color)),
        Expanded(
            flex: 1,
            child: Column(
              children: <Widget>[
                Container(
                  height: 16,
                ),
                Container(
                  height: 24,
                  child: Center(
                      child: Text(
                          FlutterI18n.translate(context, 'round.round')
                                  .toUpperCase() +
                              ' ' +
                              team1Round.roundNumber.toString(),
                          style: legendStyle)),
                ),
                Container(
                  height: 32,
                  child: Center(
                      child: Text(
                          FlutterI18n.translate(
                                  context, 'game.statistics.total')
                              .toUpperCase(),
                          style: legendStyle)),
                ),
                Container(
                  height: 24,
                  child: Center(
                      child: Text(
                          FlutterI18n.translate(
                                  context, 'game.statistics.score')
                              .toUpperCase(),
                          style: legendStyle)),
                ),
                Container(
                  height: 24,
                  child: Center(
                      child: Text(
                          FlutterI18n.translate(
                                  context, 'game.statistics.calls')
                              .toUpperCase(),
                          style: legendStyle)),
                ),
              ],
            )),
        Expanded(
            flex: 2,
            child: _teamColumn(team2Round, team2Name, widget.team2Color))
      ],
    );
  }

  Widget _accumulatedChart() {
    var teamSeries = [
      new charts.Series<RoundScoreData, int>(
        domainFn: (value, _) => value.roundNumber,
        measureFn: (value, _) => value.accumulatedScore,
        data: widget.statistics[0].rounds,
        colorFn: (_, __) => charts.Color(
            r: widget.team1Color.red,
            g: widget.team1Color.green,
            b: widget.team1Color.blue,
            a: widget.team1Color.alpha),
        id: team1Name,
      ),
      new charts.Series<RoundScoreData, int>(
        domainFn: (value, _) => value.roundNumber,
        measureFn: (value, _) => value.accumulatedScore,
        data: widget.statistics[1].rounds,
        colorFn: (_, __) => charts.Color(
            r: widget.team2Color.red,
            g: widget.team2Color.green,
            b: widget.team2Color.blue,
            a: widget.team2Color.alpha),
        id: team2Name,
      )
    ];
    if (_selectedIndex != null) {}
    return SizedBox(
      height: 300,
      child: charts.LineChart(
        teamSeries,
        primaryMeasureAxis: new charts.NumericAxisSpec(
            renderSpec: charts.GridlineRendererSpec(
              lineStyle: charts.LineStyleSpec(
                color: charts.MaterialPalette.gray.shade600,
              ),
            ),
            tickProviderSpec:
                new charts.StaticNumericTickProviderSpec(_staticTicks())),
        selectionModels: [
          new charts.SelectionModelConfig(
            type: charts.SelectionModelType.info,
            changedListener: _onChanged,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
            padding: EdgeInsets.only(left: 6), child: _accumulatedChart()),
        Container(padding: EdgeInsets.all(16), child: _selectionLegend())
      ],
    );
  }
}
