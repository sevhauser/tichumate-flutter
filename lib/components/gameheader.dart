import 'package:flutter/material.dart';
import 'package:tichumate/state/models.dart';

enum GameHeaderSlotStatus { neutral, positive, danger, accent }

class GameHeaderSlot {
  String teamName;
  List<Player> players;
  GameHeaderSlotStatus status;
  int score;
  int difference;

  GameHeaderSlot({
    required this.teamName,
    required this.players,
    required this.score,
    this.difference = 0,
    this.status = GameHeaderSlotStatus.neutral,
  });
}

class GameSummary extends StatelessWidget {
  final List<GameHeaderSlot> slots;
  final bool compact, showDifference;

  final TextStyle _teamNameStyle = const TextStyle(fontSize: 16);

  TextStyle _scoreStyle(BuildContext context, GameHeaderSlotStatus status) {
    Color? color;

    switch (status) {
      case GameHeaderSlotStatus.accent:
        color = Colors.amber.shade400;
        break;
      case GameHeaderSlotStatus.danger:
        color = Colors.red.shade500;
        break;
      case GameHeaderSlotStatus.positive:
        color = Colors.green.shade500;
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

  const GameSummary({
    required this.slots,
    this.compact = false,
    this.showDifference = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var teamNames = <Widget>[];
    var teamNamesEmpty = true;
    var scores = <Widget>[
      Text(
        ':',
        style: TextStyle(
          color: Colors.transparent,
          fontFamily: 'RobotoSlab',
          fontSize: compact ? 24 : 32,
        ),
      )
    ];
    var players = <Widget>[];
    var difference = <Widget>[];
    var playersEmpty = true;

    for (var i = 0; i < slots.length; i++) {
      if (slots[i].teamName.isNotEmpty) teamNamesEmpty = false;
      teamNames.add(Expanded(
          child: SizedBox(
              height: compact ? 36 : 36,
              child: Center(
                  child: Text(
                slots[i].teamName,
                style: _teamNameStyle,
                overflow: TextOverflow.ellipsis,
              )))));

      scores.add(Expanded(
          child: SizedBox(
        height: compact ? 32 : 36,
        child: Center(
            child: Text(slots[i].score.toString(),
                style: _scoreStyle(context, slots[i].status))),
      )));
      if (i < slots.length - 1 && !compact) {
        scores.add(Text(
          ':',
          style: TextStyle(
            fontFamily: 'RobotoSlab',
            fontSize: compact ? 24 : 32,
          ),
        ));
      } else {
        scores.add(Text(
          ':',
          style: TextStyle(
            color: Colors.transparent,
            fontFamily: 'RobotoSlab',
            fontSize: compact ? 24 : 32,
          ),
        ));
      }

      if (slots[i].players.isNotEmpty) playersEmpty = false;
      if (compact) {
        players.add(
          Expanded(
              child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
            child: SizedBox(
                height: 48,
                child: Center(
                    child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: playerNames,
                )))));
      }
      int diff = slots[i].difference;
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

  const GameHeader({
    required this.slots,
    this.showDifference = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).primaryColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
          margin: const EdgeInsets.fromLTRB(16, 40, 16, 8),
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

  const _GameSummaryPlayer({required this.player, this.compact = false});

  @override
  Widget build(BuildContext context) {
    var name = Container(
        margin: const EdgeInsets.fromLTRB(6, 4, 6, 0),
        child: Text(player.name));
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
