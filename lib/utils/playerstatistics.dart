import 'package:tichumate/state/database.dart';
import 'package:tichumate/state/models.dart';

class PlayerStatistics {
  final _db = TichuDB();
  final int playerId;
  late Player player;
  List<Team> teams = [];
  List<GameTeam> gameTeams = [];
  List<Game> games = [];
  List<Score> scores = [];

  int gamesPlayed = 0,
      gamesWon = 0,
      gamesLost = 0,
      roundsPlayed = 0,
      roundsWon = 0,
      roundsDoubleWon = 0;

  int get roundsLost => roundsPlayed - roundsWon;

  PlayerStatistics(this.playerId);

  Future<void> init() async {
    player = await TichuDB().players.getFromId(playerId);
    await _generate();
  }

  Future<void> _generate() async {
    teams = await _db.teams.getTeamsFromPlayer(playerId);
    for (var team in teams) {
      var gameTeamQuery = await _db.gameTeams
          .getWhere(where: 'team_id = ?', whereArgs: [team.id]);
      if (gameTeamQuery.isNotEmpty) {
        gameTeams.add(gameTeamQuery.first);
      }
    }
    for (var gt in gameTeams) {
      var game = await _db.games.getFromId(gt.gameId!);
      gamesPlayed += 1;
      gamesWon += gt.win ? 1 : 0;
      gamesLost += game.finished && !gt.win ? 1 : 0;
      games.add(game);

      var rounds = await _db.rounds.getFromGameId(game.id!);
      for (var r in rounds) {
        var score = r.score(gt.id!);
        if (score != null) {
          scores.add(score);
          roundsPlayed += 1;
          roundsWon += score.win > 0 ? 1 : 0;
          roundsDoubleWon += score.win == 2 ? 1 : 0;
        }
      }
    }
  }
}
