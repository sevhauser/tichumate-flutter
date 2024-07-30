abstract class TichuModel {
  int? id;

  TichuModel({this.id});

  TichuModel.fromMap(Map<String, dynamic> map);

  Map<String, dynamic> toMap();
}

class Player extends TichuModel {
  String name = '';
  String icon = '\u{1f600}';

  Player();

  Player.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    icon = map['icon'];
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }
}

class Tichu extends TichuModel {
  String title = '';
  String lang = '';
  int value = 0;
  bool protected = false;
  bool isDeleted = false;

  String get short => title.isEmpty ? 'X' : title[0].toUpperCase();

  Tichu() : super();

  Tichu.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    title = map['title'];
    lang = map['lang'];
    value = map['value'];
    protected = map['protected'] == 1;
    isDeleted = map['is_deleted'] == 1;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lang': lang,
      'value': value,
      'protected': protected ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }
}

class Team extends TichuModel {
  String name = '';
  List<Player> players = [];

  Team();

  Team.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  List<int> get playerIds {
    return players.map((player) => player.id).nonNulls.toList();
  }
}

class GameRules {
  static const String score = 'score';
  static const String difference = 'difference';
}

class Game extends TichuModel {
  DateTime createdOn = DateTime.now();
  String rule = GameRules.score;
  int winScore = 1000;
  late GameTeam team1, team2;

  bool get finished => team1.win || team2.win;

  Game();

  Game.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    if (map['created_on'] is String) {
      createdOn = DateTime.parse(map['created_on']);
    } else {
      createdOn = map['created_on'];
    }
    winScore = map['win_score'];
    rule = map['rule'];
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_on': createdOn.toIso8601String(),
      'rule': rule,
      'win_score': winScore,
    };
  }
}

class GameTeam extends TichuModel {
  int? gameId;
  int? teamId;
  int score = 0;
  bool win = false;
  Team? team;

  String get name => team?.name ?? '';
  List<Player> get players => team?.players ?? [];

  GameTeam();

  GameTeam.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    gameId = map['game_id'];
    teamId = map['team_id'];
    score = map['score'];
    win = map['win'] == 1;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'team_id': teamId,
      'score': score,
      'win': win ? 1 : 0,
    };
  }
}

class Round extends TichuModel {
  int? gameId;

  Map<int, Score> scores = {};

  Round();

  Round.forGame(this.gameId);

  Round.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    gameId = map['game_id'];
  }

  Score? score(int gameTeamId) {
    return scores[gameTeamId];
  }

  bool hasWinner() {
    bool result = false;
    for (var s in scores.values) {
      if (s.win > 0) {
        result = true;
      }
    }
    return result;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
    };
  }
}

class Score extends TichuModel {
  int? roundId;
  int? gameTeamId;
  int win = 0;
  int cardPoints = 50;

  List<Call> calls = [];

  Score();

  Score.forGameTeam(this.gameTeamId);

  int get score {
    var result = cardPoints;
    for (var call in calls) {
      result += call.score;
    }
    return result;
  }

  Score.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    roundId = map['round_id'];
    gameTeamId = map['game_team_id'];
    win = map['win'];
    cardPoints = map['card_points'];
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'round_id': roundId,
      'game_team_id': gameTeamId,
      'win': win,
      'card_points': cardPoints,
    };
  }
}

class Call extends TichuModel {
  int? scoreId;
  int? playerId;
  int? tichuId;
  int? wager;
  bool success = false;

  Call();

  Call.fromValues(
      {required this.scoreId,
      required Tichu tichu,
      this.playerId,
      this.success = false}) {
    tichuId = tichu.id;
    wager = tichu.value;
  }

  int get score => (wager ?? 0) * (success ? 1 : -1);

  Call.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    scoreId = map['score_id'];
    playerId = map['player_id'];
    tichuId = map['tichu_id'];
    wager = map['wager'];
    success = map['success'] == 1;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'score_id': scoreId,
      'player_id': playerId,
      'tichu_id': tichuId,
      'wager': wager,
      'success': success ? 1 : 0,
    };
  }
}
