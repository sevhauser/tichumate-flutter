import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tichumate/models.dart';

class TichuTable {
  static const String player = 'player',
      tichu = 'tichu',
      game = 'game',
      round = 'round',
      score = 'score',
      gameTeam = 'gameteam',
      call = 'call',
      team = 'team',
      teamPlayers = 'team_player';
  static const Map<String, List<String>> columns = {
    tichu: [
      'id',
      'title',
      'lang',
      'value',
      'protected',
      'is_deleted',
    ],
    team: ['id', 'name'],
    player: [
      'id',
      'name',
      'icon',
    ],
    game: [
      'id',
      'created_on',
      'rule',
      'win_score',
    ],
    score: [
      'id',
      'round_id',
      'game_team_id',
      'win',
      'card_points',
    ],
    gameTeam: [
      'id',
      'game_id',
      'team_id',
      'score',
      'win',
    ],
    round: [
      'id',
      'game_id',
    ],
    call: [
      'id',
      'score_id',
      'player_id',
      'tichu_id',
      'wager',
      'success',
    ],
    teamPlayers: [
      'team_id',
      'player_id',
    ]
  };
}

Future<Database> createDatabase(String name) async {
  return await openDatabase(
    join(await getDatabasesPath(), name),
    onCreate: (db, version) async {
      await db.transaction((txn) async {
        // Tables
        await txn.execute(
          'CREATE TABLE player('
          'id INTEGER PRIMARY KEY,'
          'name TEXT,'
          'icon TEXT'
          ')',
        );
        await txn.execute('CREATE TABLE IF NOT EXISTS ${TichuTable.tichu} ('
            'id INTEGER PRIMARY KEY,'
            'title TEXT,'
            'lang TEXT,'
            'value INTEGER DEFAULT 0,'
            'protected INTEGER DEFAULT 0,'
            'is_deleted INTEGER DEFAULT 0'
            ')');
        await txn.execute('CREATE TABLE IF NOT EXISTS ${TichuTable.team} ('
            'id INTEGER PRIMARY KEY,'
            'name TEXT DEFAULT ""'
            ')');
        await txn.execute('CREATE TABLE IF NOT EXISTS ${TichuTable.player} ('
            'id INTEGER PRIMARY KEY,'
            'name TEXT DEFAULT "",'
            'icon TEXT DEFAULT ""'
            ')');
        await txn.execute('CREATE TABLE IF NOT EXISTS ${TichuTable.game} ('
            'id INTEGER PRIMARY KEY,'
            'created_on TEXT DEFAULT CURRENT_TIMESTAMP,'
            'rule TEXT NOT NULL DEFAULT "score",'
            'win_score INTEGER NOT NULL DEFAULT 1000'
            ')');
        await txn.execute('CREATE TABLE IF NOT EXISTS ${TichuTable.score} ('
            'id INTEGER PRIMARY KEY,'
            'round_id INTEGER NOT NULL,'
            'game_team_id INTEGER NOT NULL,'
            'win INTEGER DEFAULT 0,'
            'card_points INTEGER DEFAULT 0'
            ')');
        await txn.execute('CREATE TABLE IF NOT EXISTS ${TichuTable.gameTeam} ('
            'id INTEGER PRIMARY KEY,'
            'game_id INTEGER NOT NULL,'
            'team_id INTEGER NOT NULL,'
            'score INTEGER DEFAULT 0,'
            'win INTEGER DEFAULT 0'
            ')');
        await txn.execute('CREATE TABLE IF NOT EXISTS ${TichuTable.round} ('
            'id INTEGER PRIMARY KEY,'
            'game_id INTEGER NOT NULL'
            ')');
        await txn.execute('CREATE TABLE IF NOT EXISTS ${TichuTable.call} ('
            'id INTEGER PRIMARY KEY,'
            'score_id INTEGER NOT NULL,'
            'player_id INTEGER,'
            'tichu_id INTEGER,'
            'wager INTEGER NOT NULL,'
            'success INTEGER NOT NULL DEFAULT 0'
            ')');
        await txn
            .execute('CREATE TABLE IF NOT EXISTS ${TichuTable.teamPlayers} ('
                'team_id INTEGER NOT NULL,'
                'player_id INTEGER NOT NULL'
                ')');

        // Indexes
        await txn.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_score_round_id_game_team_id ON ${TichuTable.score} ('
            'round_id,'
            'game_team_id'
            ')');
        await txn.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_team_player_ids ON ${TichuTable.teamPlayers} ('
            'team_id,'
            'player_id'
            ')');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_score_game_team_id ON ${TichuTable.score} ('
            'game_team_id'
            ')');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_score_round_id ON ${TichuTable.score} ('
            'round_id'
            ')');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_round_game_id ON ${TichuTable.round} ('
            'game_id'
            ')');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_round_game_id ON ${TichuTable.round} ('
            'game_id'
            ')');
        await txn.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_gameteam_game_id_team_id ON ${TichuTable.gameTeam} ('
            'game_id,'
            'team_id'
            ')');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_gameteam_game_id ON ${TichuTable.gameTeam} ('
            'game_id'
            ')');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_gameteam_team_id ON ${TichuTable.gameTeam} ('
            'team_id'
            ')');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_call_player_id ON ${TichuTable.call} ('
            'player_id'
            ')');
        await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_call_score_id ON ${TichuTable.call} ('
            'score_id'
            ')');
        // Populate
        await txn.insert(
            TichuTable.tichu,
            Tichu.fromMap({
              'title': 'Tichu',
              'lang': 'tichu.lang.tichu',
              'protected': 1,
              'value': 100
            }).toMap());
        await txn.insert(
            TichuTable.tichu,
            Tichu.fromMap({
              'title': 'Grand Tichu',
              'lang': 'tichu.lang.grand',
              'protected': 1,
              'value': 200
            }).toMap());
      });
    },
    version: 1,
  );
}

class TichuDB {
  static final TichuDB _instance = TichuDB._internal();
  bool initialized = false;
  bool testing = false;
  Database _db, db;
  PlayerRepository _players;
  TichuRepository _tichus;
  TeamRepository _teams;
  GameRepository _games;
  GameTeamRepository _gameTeams;
  RoundRepository _rounds;
  ScoreRepository _scores;
  CallRepository _calls;

  TichuDB._internal();

  factory TichuDB() {
    return _instance;
  }

  void setTesting() {
    if (initialized) {
      throw Exception(
          'Database has already been initialized. Set testing mode before calling init.');
    }
    testing = true;
  }

  Future<void> close() async {
    await _db.close();
  }

  Future<void> deleteDB() async {
    await deleteDatabase(join(await getDatabasesPath(), 'tichudb.db'));
  }

  Future<void> init() async {
    if (initialized) return;
    _db = await createDatabase(!testing ? 'tichudb.db' : 'tichudb.db');
    db = _db;
    _players = PlayerRepository(_db, this)..init();
    _tichus = TichuRepository(_db, this)..init();
    _teams = TeamRepository(_db, this)..init();
    _games = GameRepository(_db, this)..init();
    _gameTeams = GameTeamRepository(_db, this)..init();
    _rounds = RoundRepository(_db, this)..init();
    _scores = ScoreRepository(_db, this)..init();
    _calls = CallRepository(_db, this)..init();
    await _initRepos();
  }

  Future<void> _initRepos() async {
    await _players.init();
    await _tichus.init();
    await _teams.init();
    await _games.init();
    await _gameTeams.init();
    await _rounds.init();
    await _scores.init();
    await _calls.init();
  }

  PlayerRepository get players => _players;
  TichuRepository get tichus => _tichus;
  TeamRepository get teams => _teams;
  GameRepository get games => _games;
  GameTeamRepository get gameTeams => _gameTeams;
  RoundRepository get rounds => _rounds;
  ScoreRepository get scores => _scores;
  CallRepository get calls => _calls;
}

abstract class TichuRepo<E extends TichuModel> {
  final String table = '';
  final Database db;
  final TichuDB repos;

  TichuRepo(this.db, this.repos);

  E model();

  E hydratedModel(Map<String, dynamic> map);

  Future<void> init() async {
    await onDataChange();
  }

  Future<void> onDataChange() async {}

  Future<List<E>> _populateList(List<E> list) async {
    for (var i = 0; i < list.length; i++) {
      list[i] = await _populate(list[i]);
    }
    return list;
  }

  Future<E> _populate(E model) async {
    return model;
  }

  Future<E> insert(E model, {bool notifyChange: true}) async {
    int id = await db.insert(table, model.toMap());
    model.id = id;
    if (notifyChange) {
      await onDataChange();
    }
    return model;
  }

  Future<E> update(E model, {bool notifyChange: true}) async {
    await db
        .update(table, model.toMap(), where: 'id = ?', whereArgs: [model.id]);
    if (notifyChange) {
      await onDataChange();
    }
    return model;
  }

  Future<E> getFromId(int id) async {
    var results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (results.length == 0) {
      throw Exception('Model with id $id not found!');
    }
    var result = hydratedModel(results.first);
    return await _populate(result);
  }

  Future<List<E>> getFromIds(List<dynamic> ids, {String orderBy}) async {
    List<Future<E>> query = [];
    ids.forEach((id) => query.add(getFromId(id)));
    var result = await Future.wait(query);
    return await _populateList(result);
  }

  Future<List<E>> getAll({String orderBy}) async {
    var result = <E>[];
    var query = await db.query(table, orderBy: orderBy);
    query.forEach((element) {
      result.add(hydratedModel(element));
    });
    return await _populateList(result);
  }

  Future<List<E>> getWhere(
      {String where, List<dynamic> whereArgs, orderBy}) async {
    var result = <E>[];
    var query = await db.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
    query.forEach((element) {
      result.add(hydratedModel(element));
    });
    return await _populateList(result);
  }

  Future<bool> deleteFromId(int id, {bool notifyChange: true}) async {
    var result = await db.delete(table, where: 'id = ?', whereArgs: [id]);
    if (notifyChange) {
      await onDataChange();
    }
    return result > 0;
  }
}

class PlayerRepository extends TichuRepo<Player> {
  final String table = TichuTable.player;
  List<Player> players = [];
  int changeCount = 0;

  PlayerRepository(Database db, TichuDB repos) : super(db, repos);

  Player model() {
    return Player();
  }

  Player hydratedModel(Map<String, dynamic> map) {
    return Player.fromMap(map);
  }

  @override
  Future<void> onDataChange() async {
    changeCount += 1;
    players = await getAll(orderBy: 'name COLLATE NOCASE ASC');
  }

  Player getFromCache(int id) {
    var cacheIndex = players.indexWhere((player) => player.id == id);
    if (cacheIndex >= 0) {
      return players[cacheIndex];
    }
    return null;
  }

  @override
  Future<Player> getFromId(int id) async {
    var player = getFromCache(id);
    if (player != null) {
      return player;
    }
    return await super.getFromId(id);
  }

  @override
  Future<List<Player>> getFromIds(List<dynamic> ids, {String orderBy}) async {
    var result = <Player>[];
    for (var i = 0; i < ids.length; i++) {
      result.add(await getFromId(ids[i]));
    }
    return result;
  }

  @override
  Future<Player> update(Player player, {bool notifyChange: true}) async {
    var result = await super.update(player, notifyChange: notifyChange);
    await repos.games.onDataChange();
    return result;
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange: true}) async {
    await repos.teams.purgePlayer(id);
    await repos.calls.purgePlayer(id);
    var result = await super.deleteFromId(id);
    await repos.games.onDataChange();
    return result;
  }
}

class TichuRepository extends TichuRepo<Tichu> {
  final String table = TichuTable.tichu;
  List<Tichu> cachedAllTichus = [];
  List<Tichu> cachedTichus = [];
  int changeCount = 0;

  TichuRepository(Database db, TichuDB repos) : super(db, repos);

  @override
  Future<void> onDataChange() async {
    changeCount += 1;
    cachedAllTichus = await getAll(orderBy: 'protected DESC');
    cachedTichus = List<Tichu>.from(cachedAllTichus)
      ..removeWhere((tichu) => tichu.isDeleted);
  }

  Tichu model() {
    return Tichu();
  }

  Tichu hydratedModel(Map<String, dynamic> map) {
    return Tichu.fromMap(map);
  }

  Tichu getFromCache(int id) {
    var cachedIndex = cachedAllTichus.indexWhere((tichu) => tichu.id == id);
    if (cachedIndex >= 0) {
      return cachedAllTichus[cachedIndex];
    }
    return null;
  }

  @override
  Future<Tichu> getFromId(int id) async {
    var tichu = getFromCache(id);
    if (tichu == null) {
      tichu = await super.getFromId(id);
    }
    return tichu;
  }

  @override
  Future<List<Tichu>> getFromIds(List<dynamic> ids, {String orderBy}) async {
    var result = <Tichu>[];
    for (var i = 0; i < ids.length; i++) {
      result.add(await getFromId(ids[i]));
    }
    return result;
  }
}

class TeamRepository extends TichuRepo<Team> {
  final String table = TichuTable.team;

  TeamRepository(Database db, TichuDB repos) : super(db, repos);

  Team model() {
    return Team();
  }

  Team hydratedModel(Map<String, dynamic> map) {
    return Team.fromMap(map);
  }

  Future<List<Team>> getTeamsFromPlayer(int playerId) async {
    var result = <Team>[];
    var query = await db.query(TichuTable.teamPlayers,
        where: 'player_id = ?', whereArgs: [playerId]);
    if (query.isEmpty) return result;

    for (var res in query) {
      result.add(await getFromId(res['team_id']));
    }
    return result;
  }

  Future _insertPlayers(int teamId, List<int> playerIds,
      {bool clearExisting: false}) async {
    if (clearExisting) {
      await db.delete(TichuTable.teamPlayers,
          where: 'team_id = ?', whereArgs: [teamId]);
    }
    for (var i = 0; i < playerIds.length; i++) {
      await db.insert(TichuTable.teamPlayers, {
        'player_id': playerIds[i],
        'team_id': teamId,
      });
    }
  }

  Future<List<Player>> _players(int teamId) async {
    var query = await db.query(TichuTable.teamPlayers,
        where: 'team_id = ?', whereArgs: [teamId]);
    return await repos.players
        .getFromIds(query.map((item) => item['player_id']).toList());
  }

  @override
  Future<Team> _populate(Team team) async {
    var result = team;
    team.players = await _players(team.id);
    return result;
  }

  @override
  Future<Team> insert(Team team, {bool notifyChange: true}) async {
    var result = await super.insert(team, notifyChange: notifyChange);
    await _insertPlayers(result.id, result.playerIds);
    return result;
  }

  @override
  Future<Team> update(Team team, {bool notifyChange: true}) async {
    var result = await super.update(team, notifyChange: notifyChange);
    await _insertPlayers(result.id, result.playerIds, clearExisting: true);
    return team;
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange: true}) async {
    await db
        .delete(TichuTable.teamPlayers, where: 'team_id = ?', whereArgs: [id]);
    return await super.deleteFromId(id, notifyChange: notifyChange);
  }

  Future<void> purgePlayer(int playerId) async {
    await db.delete(TichuTable.teamPlayers,
        where: 'player_id = ?', whereArgs: [playerId]);
    await onDataChange();
  }
}

class GameRepository extends TichuRepo<Game> {
  final String table = TichuTable.game;
  List<Game> cachedGames = [];
  int changeCount = 0;

  GameRepository(Database db, TichuDB repos) : super(db, repos);

  Game model() {
    return Game();
  }

  Game hydratedModel(Map<String, dynamic> map) {
    return Game.fromMap(map);
  }

  @override
  Future<void> onDataChange() async {
    changeCount += 1;
    cachedGames = await getAll(orderBy: 'created_on DESC');
  }

  @override
  Future<void> init() async {
    await onDataChange();
  }

  @override
  Future<Game> _populate(Game game) async {
    var teams = await repos.gameTeams.getFromGameId(game.id);
    assert(teams.length == 2);
    game.team1 = teams[0];
    game.team2 = teams[1];
    return game;
  }

  Future<Game> create(Game game, Team team1, Team team2) async {
    var newGame = await insert(game, notifyChange: false);
    // Team 1
    var newTeam1 = await repos.teams.insert(team1);
    var gameTeam1 = await repos.gameTeams.create(newGame, newTeam1);
    newGame.team1 = gameTeam1;

    // Team 2
    var newTeam2 = await repos.teams.insert(team2);
    var gameTeam2 = await repos.gameTeams.create(newGame, newTeam2);
    newGame.team2 = gameTeam2;
    await onDataChange();
    return newGame;
  }

  @override
  Future<Game> update(Game game, {bool notifyChange: true}) async {
    await super.update(game, notifyChange: false);
    await repos.gameTeams.update(game.team1);
    await repos.gameTeams.update(game.team2);
    await onDataChange();
    return game;
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange: true}) async {
    await repos.gameTeams.purgeGame(id);
    await repos.rounds.purgeGame(id);
    return await super.deleteFromId(id, notifyChange: notifyChange);
  }
}

class GameTeamRepository extends TichuRepo<GameTeam> {
  final String table = TichuTable.gameTeam;

  GameTeamRepository(Database db, TichuDB repos) : super(db, repos);

  GameTeam model() {
    return GameTeam();
  }

  GameTeam hydratedModel(Map<String, dynamic> map) {
    return GameTeam.fromMap(map);
  }

  @override
  Future<GameTeam> _populate(GameTeam gameTeam) async {
    var result = gameTeam;
    gameTeam.team = await repos.teams.getFromId(result.teamId);
    return gameTeam;
  }

  Future<List<GameTeam>> getFromGameId(int id) async {
    return await getWhere(where: 'game_id = ?', whereArgs: [id]);
  }

  Future<GameTeam> create(Game game, Team team) async {
    var gameTeam = GameTeam()
      ..gameId = game.id
      ..teamId = team.id;
    return await insert(gameTeam);
  }

  @override
  Future<GameTeam> update(GameTeam team, {bool notifyChange: true}) async {
    var result = await super.update(team, notifyChange: false);
    await repos.teams.update(result.team);
    onDataChange();
    return result;
  }

  Future<void> purgeGame(int id) async {
    var query = await db.query(table, where: 'game_id = ?', whereArgs: [id]);
    for (var gameTeam in query) {
      await deleteFromId(gameTeam['id']);
    }
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange: true}) async {
    var gameTeam = await getFromId(id);
    await repos.teams.deleteFromId(gameTeam.teamId);
    return await super.deleteFromId(id, notifyChange: notifyChange);
  }
}

class RoundRepository extends TichuRepo<Round> {
  final String table = TichuTable.round;

  RoundRepository(Database db, TichuDB repos) : super(db, repos);

  Round model() {
    return Round();
  }

  Round hydratedModel(Map<String, dynamic> map) {
    return Round.fromMap(map);
  }

  Future<Round> _populate(Round round) async {
    var scores = await repos.scores.getWhere(
      where: 'round_id = ?',
      whereArgs: [round.id],
    );
    assert(scores.length == 2);
    round.scores[scores[0].gameTeamId] = scores[0];
    round.scores[scores[1].gameTeamId] = scores[1];
    return round;
  }

  @override
  Future<Round> insert(Round round, {bool notifyChange: true}) async {
    var newRound = await super.insert(round);
    for (int i in newRound.scores.keys) {
      newRound.scores[i].roundId = newRound.id;
      newRound.scores[i] = await repos.scores.insert(newRound.scores[i]);
    }
    return newRound;
  }

  @override
  Future<Round> update(Round round, {bool notifyChange: true}) async {
    var updatedRound = await super.update(round, notifyChange: false);
    await repos.scores.purgeRound(round.id);
    for (int i in updatedRound.scores.keys) {
      updatedRound.scores[i].roundId = updatedRound.id;
      updatedRound.scores[i] =
          await repos.scores.insert(updatedRound.scores[i]);
    }
    await onDataChange();
    return updatedRound;
  }

  Future<List<Round>> getFromGameId(int gameId) async {
    return await getWhere(where: 'game_id = ?', whereArgs: [gameId]);
  }

  Future<void> purgeGame(int gameId) async {
    var query =
        await db.query(table, where: 'game_id = ?', whereArgs: [gameId]);
    for (var round in query) {
      await deleteFromId(round['id']);
    }
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange: true}) async {
    await repos.scores.purgeRound(id);
    return await super.deleteFromId(id, notifyChange: notifyChange);
  }
}

class ScoreRepository extends TichuRepo<Score> {
  final String table = TichuTable.score;

  ScoreRepository(Database db, TichuDB repos) : super(db, repos);

  @override
  Future<Score> _populate(Score score) async {
    var result = score;
    result.calls = await repos.calls.getFromScoreId(score.id);
    return result;
  }

  Score model() {
    return Score();
  }

  Score hydratedModel(Map<String, dynamic> map) {
    return Score.fromMap(map);
  }

  @override
  Future<Score> insert(Score score, {bool notifyChange: true}) async {
    var newScore = await super.insert(score);
    for (var i = 0; i < score.calls.length; i++) {
      newScore.calls[i].scoreId = newScore.id;
      newScore.calls[i] = await repos.calls.insert(newScore.calls[i]);
    }
    return newScore;
  }

  Future<void> purgeRound(int roundId) async {
    var query =
        await db.query(table, where: 'round_id = ?', whereArgs: [roundId]);
    for (var score in query) {
      await deleteFromId(score['id']);
    }
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange: true}) async {
    await repos.calls.purgeScore(id);
    return await super.deleteFromId(id, notifyChange: notifyChange);
  }
}

class CallRepository extends TichuRepo<Call> {
  final String table = TichuTable.call;

  CallRepository(Database db, TichuDB repos) : super(db, repos);

  Call model() {
    return Call();
  }

  Call hydratedModel(Map<String, dynamic> map) {
    return Call.fromMap(map);
  }

  Future<List<Call>> getFromScoreId(int id) async {
    return await getWhere(where: 'score_id = ?', whereArgs: [id]);
  }

  Future<void> purgePlayer(int playerId) async {
    var query = await getWhere(where: 'player_id = ?', whereArgs: [playerId]);
    for (var call in query) {
      call.playerId = null;
      await update(call);
    }
    await onDataChange();
  }

  Future<void> purgeScore(int scoreId) async {
    var query =
        await db.query(table, where: 'score_id = ?', whereArgs: [scoreId]);
    for (var call in query) {
      await deleteFromId(call['id']);
    }
  }
}
