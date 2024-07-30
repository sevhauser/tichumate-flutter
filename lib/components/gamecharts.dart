import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:tichumate/state/database.dart';
import 'package:tichumate/utils/gamemanager.dart';

class GameStatistics extends StatefulWidget {
  final GameManager gameManager;

  const GameStatistics({
    super.key,
    required this.gameManager,
  });

  @override
  State<GameStatistics> createState() => _GameStatisticsState();
}

class _GameStatisticsState extends State<GameStatistics> {
  GameManager get _m => widget.gameManager;
  late GameStatisticsProvider _sp;

  @override
  void initState() {
    super.initState();
    _sp = _m.statistics();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.transparent,
        margin: const EdgeInsets.only(top: 24),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
                FlutterI18n.translate(context, 'game.statistics.statistics')),
          ),
          body: ListView(
            shrinkWrap: true,
            children: <Widget>[
              _ScoreChartCard(statisticsProvider: _sp),
              const Divider(),
            ],
          ),
        ));
  }
}

class _ScoreChartCard extends StatelessWidget {
  final GameStatisticsProvider statisticsProvider;
  const _ScoreChartCard({
    required this.statisticsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            FlutterI18n.translate(context, 'game.statistics.score_total'),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        _ScoreChart(
          statistics: [
            statisticsProvider.statistics.values.first,
            statisticsProvider.statistics.values.last,
          ],
          team1Color: Colors.tealAccent.shade400,
          team2Color: Colors.red.shade500,
          winScore: null,
        ),
      ],
    );
  }
}

class _ScoreChart extends StatefulWidget {
  final List<TeamStatistics> statistics;
  final Color team1Color, team2Color;
  final int? winScore;
  const _ScoreChart(
      {required this.statistics,
      required this.team1Color,
      required this.team2Color,
      required this.winScore});

  @override
  __ScoreChartState createState() => __ScoreChartState();
}

class __ScoreChartState extends State<_ScoreChart> {
  int _selectedIndex = 0;

  String get team1Name {
    if (widget.statistics[0].team.name.isEmpty) {
      return '${FlutterI18n.translate(context, 'team.team')} 1';
    }
    return widget.statistics[0].team.name;
  }

  String get team2Name {
    if (widget.statistics[1].team.name.isEmpty) {
      return '${FlutterI18n.translate(context, 'team.team')} 2';
    }
    return widget.statistics[1].team.name;
  }

  Widget _teamColumn(RoundScoreData data, String teamName, Color teamColor) {
    var rows = <Widget>[
      SizedBox(
          height: 16,
          child: Center(
              child: Icon(
            Icons.brightness_1,
            color: teamColor,
            size: 12,
          ))),
      SizedBox(
          height: 24,
          child: Center(
            child: Text(
              teamName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          )),
    ];
    rows.add(SizedBox(
        height: 32,
        child: Center(
            child: Text(
          data.accumulatedScore.toString(),
          style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 24,
              color: data.win
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white),
        ))));

    Color scoreColor;
    if (data.score > 0) {
      scoreColor = Colors.green.shade300;
    } else if (data.score < 0) {
      scoreColor = Colors.red.shade300;
    } else {
      scoreColor = Colors.white;
    }

    rows.add(SizedBox(
        height: 24,
        child: Center(
            child: Text(data.score.toString(),
                style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 18,
                    color: scoreColor)))));
    var calls = data.calls.map((c) {
      var tichu = TichuDB().tichus.getFromCache(c.tichuId!)!;
      var title = tichu.lang.isEmpty
          ? tichu.short
          : FlutterI18n.translate(context, '${tichu.lang}.short');
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(title,
              style: TextStyle(
                  color:
                      c.success ? Colors.green.shade500 : Colors.red.shade500,
                  fontSize: 16)));
    }).toList();
    rows.add(SizedBox(
        height: 24,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: calls.isEmpty
                ? [const Text('', style: TextStyle(fontSize: 16))]
                : calls)));
    return Column(
      children: rows,
    );
  }

  Widget _selectionLegend() {
    if (_selectedIndex < 0) {
      return const SizedBox();
    }
    var team1Round = widget.statistics[0].rounds[_selectedIndex];
    var team2Round = widget.statistics[1].rounds[_selectedIndex];
    const legendStyle = TextStyle(color: Colors.white54);
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
                SizedBox(
                  height: 24,
                  child: Center(
                      child: Text(
                          '${FlutterI18n.translate(context, 'round.round').toUpperCase()} ${team1Round.roundNumber}',
                          style: legendStyle)),
                ),
                SizedBox(
                  height: 32,
                  child: Center(
                      child: Text(
                          FlutterI18n.translate(
                                  context, 'game.statistics.total')
                              .toUpperCase(),
                          style: legendStyle)),
                ),
                SizedBox(
                  height: 24,
                  child: Center(
                      child: Text(
                          FlutterI18n.translate(
                                  context, 'game.statistics.score')
                              .toUpperCase(),
                          style: legendStyle)),
                ),
                SizedBox(
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

  // Widget _accumulatedChart() {
  //   var teamSeries = [
  //     charts.Series<RoundScoreData, int>(
  //       domainFn: (value, _) => value.roundNumber,
  //       measureFn: (value, _) => value.accumulatedScore,
  //       data: widget.statistics[0].rounds,
  //       colorFn: (_, __) => charts.Color(
  //           r: widget.team1Color.red,
  //           g: widget.team1Color.green,
  //           b: widget.team1Color.blue,
  //           a: widget.team1Color.alpha),
  //       id: team1Name,
  //     ),
  //     new charts.Series<RoundScoreData, int>(
  //       domainFn: (value, _) => value.roundNumber,
  //       measureFn: (value, _) => value.accumulatedScore,
  //       data: widget.statistics[1].rounds,
  //       colorFn: (_, __) => charts.Color(
  //           r: widget.team2Color.red,
  //           g: widget.team2Color.green,
  //           b: widget.team2Color.blue,
  //           a: widget.team2Color.alpha),
  //       id: team2Name,
  //     )
  //   ];
  //   return SizedBox(
  //     height: 300,
  //     child: charts.LineChart(
  //       teamSeries,
  //       primaryMeasureAxis: new charts.NumericAxisSpec(
  //           renderSpec: charts.GridlineRendererSpec(
  //             lineStyle: charts.LineStyleSpec(
  //               color: charts.MaterialPalette.gray.shade600,
  //             ),
  //           ),
  //           tickProviderSpec:
  //               new charts.StaticNumericTickProviderSpec(_staticTicks())),
  //       selectionModels: [
  //         new charts.SelectionModelConfig(
  //           type: charts.SelectionModelType.info,
  //           changedListener: _onChanged,
  //         )
  //       ],
  //     ),
  //   );
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Column(
  //     children: <Widget>[
  //       Container(
  //           padding: const EdgeInsets.only(left: 6),
  //           child: _accumulatedChart()),
  //       Container(padding: const EdgeInsets.all(16), child: _selectionLegend())
  //     ],
  //   );
  // }

  LineChartBarData _teamBarData(TeamStatistics statistics, Color lineColor) {
    return LineChartBarData(
        color: lineColor,
        spots: statistics.rounds
            .map((round) => FlSpot(round.roundNumber.toDouble(),
                round.accumulatedScore.toDouble()))
            .toList(),
        dotData: const FlDotData(show: false));
  }

  LineChartBarData get _team1BarData =>
      _teamBarData(widget.statistics[0], Colors.teal.shade400);
  LineChartBarData get _team2BarData =>
      _teamBarData(widget.statistics[1], Colors.red.shade500);

  LineChartData _chartData(BuildContext context) {
    return LineChartData(
        lineBarsData: [
          _team1BarData,
          _team2BarData,
        ],
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 24,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )),
            leftTitles: AxisTitles(
                axisNameSize: 50,
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 100,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ))),
        minX: 0,
        gridData: FlGridData(
            show: true,
            verticalInterval: 1,
            horizontalInterval: 100,
            getDrawingHorizontalLine: (value) => const FlLine(
                  color: Colors.white24,
                  strokeWidth: 1,
                ),
            getDrawingVerticalLine: (value) => const FlLine(
                  color: Colors.white24,
                  strokeWidth: 1,
                )),
        lineTouchData: LineTouchData(
          touchCallback: (FlTouchEvent event, LineTouchResponse? lineTouch) {
            if (!event.isInterestedForInteractions ||
                lineTouch == null ||
                lineTouch.lineBarSpots == null) {
              return;
            }
            final value = lineTouch.lineBarSpots![0].x.toInt();

            if (value == 0 || value == 6) {
              return;
            }

            setState(() {
              _selectedIndex = value;
            });
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: AspectRatio(
                aspectRatio: 1.5, child: LineChart(_chartData(context)))),
        Container(padding: const EdgeInsets.all(16), child: _selectionLegend())
      ],
    );
  }
}
