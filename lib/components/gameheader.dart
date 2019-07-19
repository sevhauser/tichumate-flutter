import 'package:flutter/material.dart';
import 'package:tichumate/models.dart';

enum GameHeaderSlotStatus { neutral, positive, danger, accent }

class GameHeaderSlot {
  String teamName;
  List<Player> players;
  GameHeaderSlotStatus status;
  int score;
  int difference;

  GameHeaderSlot({
    @required this.teamName,
    @required this.players,
    @required this.score,
    this.difference,
    this.status: GameHeaderSlotStatus.neutral,
  });
}

class GameSummary extends StatelessWidget {
  final List<GameHeaderSlot> slots;
  final bool compact, showDifference;

  final TextStyle _teamNameStyle = const TextStyle(fontSize: 16);

  TextStyle _scoreStyle(BuildContext context, GameHeaderSlotStatus status) {
    var color;

    switch (status) {
      case GameHeaderSlotStatus.accent:
        color = Theme.of(context).accentColor;
        break;
      case GameHeaderSlotStatus.danger:
        color = Colors.red[500];
        break;
      case GameHeaderSlotStatus.positive:
        color = Colors.green[500];
        break;
      default:
        break;
    }
    return TextStyle(
      fontFamily: 'RobotoSlab',
      fontSize: compact ? 24 : 32,
      color: color,
    );
  }

  GameSummary({
    @required this.slots,
    this.compact: false,
    this.showDifference: false,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var teamNames = <Widget>[];
    var teamNamesEmpty = true;
    var scores = <Widget>[
      Container(
        child: Text(
          ':',
          style: TextStyle(
            color: Colors.transparent,
            fontFamily: 'RobotoSlab',
            fontSize: compact ? 24 : 32,
          ),
        ),
      )
    ];
    var players = <Widget>[];
    var difference = <Widget>[];
    var playersEmpty = true;

    for (var i = 0; i < slots.length; i++) {
      if (slots[i].teamName.isNotEmpty) teamNamesEmpty = false;
      teamNames.add(Expanded(
          child: Container(
              height: compact ? 36 : 44,
              child: Center(
                  child: Text(
                slots[i].teamName,
                style: _teamNameStyle,
                overflow: TextOverflow.ellipsis,
              )))));

      scores.add(Expanded(
          child: Container(
        height: compact ? 36 : 44,
        child: Center(
            child: Text(slots[i].score.toString(),
                style: _scoreStyle(context, slots[i].status))),
      )));
      if (i < slots.length - 1 && !compact) {
        scores.add(Container(
          child: Text(
            ':',
            style: TextStyle(
              fontFamily: 'RobotoSlab',
              fontSize: compact ? 24 : 32,
            ),
          ),
        ));
      } else {
        scores.add(Container(
          child: Text(
            ':',
            style: TextStyle(
              color: Colors.transparent,
              fontFamily: 'RobotoSlab',
              fontSize: compact ? 24 : 32,
            ),
          ),
        ));
      }

      if (slots[i].players.isNotEmpty) playersEmpty = false;
      if (compact) {
        players.add(
          Expanded(
              child: Container(
                  height: 32,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                      child: Text(
                    slots[i].players.map((p) => p.name).toList().join(', '),
                    overflow: TextOverflow.ellipsis,
                  )))),
        );
      } else {
        var playerNames = slots[i]
            .players
            .map((player) => _GameSummaryPlayer(
                  player: player,
                  compact: compact,
                ))
            .toList();
        players.add(Expanded(
            child: Container(
                height: 52,
                child: Center(
                    child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: playerNames,
                )))));
      }
      int diff = slots[i].difference == null ? 0 : slots[i].difference;
      difference.add(Expanded(
          child: Text(
        diff <= 0 ? '' : '+${diff.toString()}',
        textAlign: TextAlign.center,
      )));
    }
    var result = <Widget>[];
    if (!teamNamesEmpty) {
      result.add(Row(
        children: teamNames,
      ));
    }
    result.add(Row(
      children: scores,
    ));

    if (showDifference) {
      result.add(Row(
        children: difference,
      ));
    }

    if (!playersEmpty) {
      result.add(Row(
        children: players,
      ));
    }

    return Column(
      children: result,
    );
  }
}

class GameHeader extends StatelessWidget {
  final List<GameHeaderSlot> slots;
  final bool showDifference;
  final TextStyle _scoreStyle =
      const TextStyle(fontFamily: 'RobotoSlab', fontSize: 32);

  GameHeader({
    @required this.slots,
    this.showDifference: false,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
          margin: EdgeInsets.fromLTRB(16, 40, 16, 8),
          child: GameSummary(
            showDifference: showDifference,
            slots: slots,
          )),
    );
  }
}

class _GameSummaryPlayer extends StatelessWidget {
  final Player player;
  final bool compact;

  _GameSummaryPlayer({@required this.player, this.compact: false});

  @override
  Widget build(BuildContext context) {
    var name = Container(
        child: Text(player.name), margin: EdgeInsets.fromLTRB(6, 4, 6, 0));
    if (compact) return name;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(player.icon),
        name,
      ],
    );
  }
}
