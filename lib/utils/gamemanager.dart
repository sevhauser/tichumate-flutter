import 'package:flutter/material.dart';
import 'package:tichumate/components/gameheader.dart';
import 'package:tichumate/database.dart';
import 'package:tichumate/models.dart';

class GameManager {
  int gameId;
  Game game;
  List<Round> rounds;
  bool initialized = false;
  TichuDB _db;

  int get team1Id => game.team1.id;
  int get team2Id => game.team2.id;
  GameTeam get team1 => game.team1;
  GameTeam get team2 => game.team2;

  GameHeaderSlotStatus get team1Status => _teamStatus(team1);
  GameHeaderSlotStatus get team2Status => _teamStatus(team2);

  int get team1Difference => team1.score - team2.score;
  int get team2Difference => team2.score - team1.score;

  GameManager({@required this.gameId}) {
    _db = TichuDB();
  }

  Future<void> init() async {
    game = await _db.games.getFromId(gameId);
    rounds = await _db.rounds.getFromGameId(game.id);
  }

  GameHeaderSlotStatus _teamStatus(GameTeam team) {
    if (team.win) {
      return GameHeaderSlotStatus.accent;
    }
    return GameHeaderSlotStatus.neutral;
  }

  void _recalculate() {
    team1.score = 0;
    team2.score = 0;
    rounds.forEach((round) {
      team1.score += round.score(team1Id).score;
      team2.score += round.score(team2Id).score;
    });
    var team1Win = false, team2Win = false;
    switch (game.rule) {
      case GameRules.score:
        team1Win = team1.score >= game.winScore && team1.score > team2.score;
        team2Win = team2.score >= game.winScore && team2.score > team1.score;
        break;
      case GameRules.difference:
        team1Win = team1.score > team2.score &&
            (team1.score - team2.score) >= game.winScore;
        team2Win = team2.score > team1.score &&
            (team2.score - team1.score) >= game.winScore;
        break;
    }
    team1.win = team1Win;
    team2.win = team2Win;
  }

  Future<void> delete() async {
    await _db.games.deleteFromId(gameId);
  }

  Future<void> save() async {
    _recalculate();
    await _db.games.update(game);
  }

  Future<void> addRound(Round round) async {
    assert(round.gameId == game.id);
    rounds.add(round);
    await save();
  }

  Future<void> removeRound(int roundId) async {
    var roundIndex = rounds.indexWhere((round) => round.id == roundId);
    if (roundIndex < 0) return;
    await _db.rounds.deleteFromId(rounds[roundIndex].id);
    rounds.removeAt(roundIndex);
    await save();
  }

  Future<void> saveRound(RoundManager rm) async {
    if (rm.newRound) {
      var createdRound = await _db.rounds.insert(rm.round);
      rounds.add(createdRound);
    } else {
      var updatedRound = await _db.rounds.update(rm.round);
      var roundIndex = rounds.indexWhere((r) => r.id == rm.roundId);
      if (roundIndex >= 0) {
        rounds[roundIndex] = updatedRound;
      }
    }
    await save();
  }

  RoundManager roundManager({int roundId}) {
    if (roundId == null) {
      var round = Round.forGame(game.id);
      round.scores[team1Id] = Score.forGameTeam(team1Id);
      round.scores[team2Id] = Score.forGameTeam(team2Id);
      return RoundManager(gameManager: this, game: game, round: round);
    }
    return RoundManager(
        gameManager: this,
        game: game,
        round: rounds.firstWhere((r) => r.id == roundId));
  }

  GameStatisticsProvider statistics() {
    return GameStatisticsProvider(gameManager: this)..generateData();
  }
}

class RoundManager {
  GameManager gameManager;
  int gameId, roundId;
  final int _baseScoreDistribution = 0;
  Round round;
  Game game;
  int _scoreDistribution;

  RoundManager({
    @required this.gameManager,
    @required this.game,
    @required this.round,
  }) {
    if (newRound || hasDoubleWin) {
      _scoreDistribution = _baseScoreDistribution;
    } else {
      _scoreDistribution = 50 - round.scores[team1Id].cardPoints;
    }
  }

  bool get newRound => round.id == null;

  int get team1Id => game.team1.id;
  int get team2Id => game.team2.id;
  GameTeam get team1 => game.team1;
  GameTeam get team2 => game.team2;

  Score get score1 => round.score(team1Id);
  Score get score2 => round.score(team2Id);

  bool get hasWinner => round.hasWinner();

  int get scoreDistribution {
    return hasDoubleWin ? _baseScoreDistribution : _scoreDistribution;
  }

  set scoreDistribution(int value) {
    _scoreDistribution = value;
    score1.cardPoints = 50 - value;
    score2.cardPoints = 50 + value;
  }

  GameHeaderSlotStatus get score1Status => _scoreStatus(team1Id);
  GameHeaderSlotStatus get score2Status => _scoreStatus(team2Id);

  GameHeaderSlotStatus _scoreStatus(int gameTeamId) {
    var result;
    switch (round.score(gameTeamId).win) {
      case 1:
      case 2:
        result = GameHeaderSlotStatus.accent;
        break;
      default:
        result = GameHeaderSlotStatus.neutral;
    }
    return result;
  }

  bool get hasDoubleWin {
    return score1.win == 2 || score2.win == 2;
  }

  void win1({bool doubleWin: false}) {
    if (doubleWin && score1.win != 2) {
      score1.win = 2;
    } else {
      score1.win = 1;
    }
    score2.win = 0;
    if (score1.win == 2) {
      score1.cardPoints = 200;
      score2.cardPoints = 0;
    } else {
      scoreDistribution = _scoreDistribution;
    }
  }

  void win2({bool doubleWin: false}) {
    if (doubleWin && score2.win != 2) {
      score2.win = 2;
    } else {
      score2.win = 1;
    }
    score1.win = 0;
    if (score2.win == 2) {
      score2.cardPoints = 200;
      score1.cardPoints = 0;
    } else {
      scoreDistribution = _scoreDistribution;
    }
  }

  void team1Call(Call call) {
    teamCall(score1, call);
  }

  void team2Call(Call call) {
    teamCall(score2, call);
  }

  void teamCall(Score score, Call call) {
    var index = score.calls.indexWhere(
        (c) => c.tichuId == call.tichuId && c.success == call.success);
    if (index >= 0) {
      score.calls.removeAt(index);
    } else {
      score.calls.add(call);
    }
  }

  Call team1CallInfo(int tichuId, bool success) {
    return _callInfo(score1.calls, tichuId, success);
  }

  Call team2CallInfo(int tichuId, bool success) {
    return _callInfo(score2.calls, tichuId, success);
  }

  Call _callInfo(List<Call> calls, int tichuId, bool success) {
    var index = calls.indexWhere(
        (call) => call.tichuId == tichuId && call.success == success);
    if (index >= 0) {
      return calls[index];
    }
    return null;
  }

  Future<void> save() async {
    await gameManager.saveRound(this);
  }
}

class GameStatisticsProvider {
  final GameManager gameManager;
  Map<int, TeamStatistics> statistics = {};

  GameManager get _m => gameManager;

  GameStatisticsProvider({
    @required this.gameManager,
  });

  void generateData() {
    var ts1 = TeamStatistics(team: _m.team1),
        ts2 = TeamStatistics(team: _m.team2);
    _m.rounds.forEach((round) {
      var score1 = round.score(_m.team1Id);
      ts1.wins += score1.win > 0 ? 1 : 0;
      ts1.doubleWins += score1.win == 2 ? 1 : 0;
      ts1.winStreak = (score1.win > 0) ? ts1.winStreak + 1 : 0;
      ts1.roundScores.add(score1.score);
      ts1.addRoundScore(score1);

      var score2 = round.score(_m.team2Id);
      ts2.wins += score2.win > 0 ? 1 : 0;
      ts2.doubleWins += score2.win == 2 ? 1 : 0;
      ts2.winStreak = (score2.win > 0) ? ts2.winStreak + 1 : 0;
      ts2.roundScores.add(score2.score);
      ts2.addRoundScore(score2);
    });
    ts1.generateData();
    ts2.generateData();
    statistics[_m.team1Id] = ts1;
    statistics[_m.team2Id] = ts2;
  }
}

class TeamStatistics {
  final GameTeam team;
  int wins = 0,
      doubleWins = 0,
      winStreak = 0,
      avgScore = 0,
      maxScore = 0,
      minScore = 0;
  List<RoundScoreData> rounds = [
    RoundScoreData(
      roundNumber: 0,
      score: 0,
      accumulatedScore: 0,
      calls: [],
    ),
  ];
  List<int> roundScores = [0];
  List<int> accumulatedRoundScores = [0];

  TeamStatistics({
    @required this.team,
  });

  void addRoundScore(Score score) {
    rounds.add(RoundScoreData(
      roundNumber: rounds.length,
      score: score.score,
      accumulatedScore: rounds.last.accumulatedScore + score.score,
      win: score.win > 0,
      doubleWin: score.win == 2,
      calls: score.calls,
    ));
  }

  void generateData() {
    for (var score in rounds) {
      wins += score.win ? 1 : 0;
      doubleWins += score.doubleWin ? 1 : 0;
      winStreak = score.win ? winStreak + 1 : 0;
      maxScore =
          score.accumulatedScore > maxScore ? score.accumulatedScore : maxScore;
      minScore =
          score.accumulatedScore < minScore ? score.accumulatedScore : minScore;
    }
  }
}

class RoundScoreData {
  final int roundNumber, score, accumulatedScore;
  bool win, doubleWin;
  final List<Call> calls;

  RoundScoreData({
    @required this.roundNumber,
    @required this.score,
    @required this.accumulatedScore,
    @required this.calls,
    this.win: false,
    this.doubleWin: false,
  });
}
