import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tichumate/state/models.dart';

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
  late Database _db, db;
  late PlayerRepository _players;
  late TichuRepository _tichus;
  late TeamRepository _teams;
  late GameRepository _games;
  late GameTeamRepository _gameTeams;
  late RoundRepository _rounds;
  late ScoreRepository _scores;
  late CallRepository _calls;

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
  String get table;
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

  Future<E> insert(E model, {bool notifyChange = true}) async {
    int id = await db.insert(table, model.toMap());
    model.id = id;
    if (notifyChange) {
      await onDataChange();
    }
    return model;
  }

  Future<E> update(E model, {bool notifyChange = true}) async {
    await db
        .update(table, model.toMap(), where: 'id = ?', whereArgs: [model.id]);
    if (notifyChange) {
      await onDataChange();
    }
    return model;
  }

  Future<E> getFromId(int id) async {
    var results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) {
      throw Exception('Model with id $id not found!');
    }
    var result = hydratedModel(results.first);
    return await _populate(result);
  }

  Future<List<E>> getFromIds(List<dynamic> ids, {String? orderBy}) async {
    List<Future<E>> query = [];
    for (var id in ids) {
      query.add(getFromId(id));
    }
    var result = await Future.wait(query);
    return await _populateList(result);
  }

  Future<List<E>> getAll({String? orderBy}) async {
    var result = <E>[];
    var query = await db.query(table, orderBy: orderBy);
    for (var element in query) {
      result.add(hydratedModel(element));
    }
    return await _populateList(result);
  }

  Future<List<E>> getWhere(
      {required String where,
      required List<dynamic> whereArgs,
      orderBy}) async {
    var result = <E>[];
    var query = await db.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
    for (var element in query) {
      result.add(hydratedModel(element));
    }
    return await _populateList(result);
  }

  Future<bool> deleteFromId(int id, {bool notifyChange = true}) async {
    var result = await db.delete(table, where: 'id = ?', whereArgs: [id]);
    if (notifyChange) {
      await onDataChange();
    }
    return result > 0;
  }
}

class PlayerRepository extends TichuRepo<Player> {
  @override
  String get table => TichuTable.player;
  List<Player> players = [];
  int changeCount = 0;

  PlayerRepository(super.db, super.repos);

  @override
  Player model() {
    return Player();
  }

  @override
  Player hydratedModel(Map<String, dynamic> map) {
    return Player.fromMap(map);
  }

  @override
  Future<void> onDataChange() async {
    changeCount += 1;
    players = await getAll(orderBy: 'name COLLATE NOCASE ASC');
  }

  Player? getFromCache(int id) {
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
  Future<List<Player>> getFromIds(List<dynamic> ids, {String? orderBy}) async {
    var result = <Player>[];
    for (var i = 0; i < ids.length; i++) {
      result.add(await getFromId(ids[i]));
    }
    return result;
  }

  @override
  Future<Player> update(Player model, {bool notifyChange = true}) async {
    var result = await super.update(model, notifyChange: notifyChange);
    await repos.games.onDataChange();
    return result;
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange = true}) async {
    await repos.teams.purgePlayer(id);
    await repos.calls.purgePlayer(id);
    var result = await super.deleteFromId(id);
    await repos.games.onDataChange();
    return result;
  }
}

class TichuRepository extends TichuRepo<Tichu> {
  @override
  String get table => TichuTable.tichu;
  List<Tichu> cachedAllTichus = [];
  List<Tichu> cachedTichus = [];
  int changeCount = 0;

  TichuRepository(super.db, super.repos);

  @override
  Future<void> onDataChange() async {
    changeCount += 1;
    cachedAllTichus = await getAll(orderBy: 'protected DESC');
    cachedTichus = List<Tichu>.from(cachedAllTichus)
      ..removeWhere((tichu) => tichu.isDeleted);
  }

  @override
  Tichu model() {
    return Tichu();
  }

  @override
  Tichu hydratedModel(Map<String, dynamic> map) {
    return Tichu.fromMap(map);
  }

  Tichu? getFromCache(int id) {
    var cachedIndex = cachedAllTichus.indexWhere((tichu) => tichu.id == id);
    if (cachedIndex >= 0) {
      return cachedAllTichus[cachedIndex];
    }
    return null;
  }

  @override
  Future<Tichu> getFromId(int id) async {
    var tichu = getFromCache(id);
    tichu ??= await super.getFromId(id);
    return tichu;
  }

  @override
  Future<List<Tichu>> getFromIds(List<dynamic> ids, {String? orderBy}) async {
    var result = <Tichu>[];
    for (var i = 0; i < ids.length; i++) {
      result.add(await getFromId(ids[i]));
    }
    return result;
  }
}

class TeamRepository extends TichuRepo<Team> {
  @override
  String get table => TichuTable.team;

  TeamRepository(super.db, super.repos);

  @override
  Team model() {
    return Team();
  }

  @override
  Team hydratedModel(Map<String, dynamic> map) {
    return Team.fromMap(map);
  }

  Future<List<Team>> getTeamsFromPlayer(int playerId) async {
    var result = <Team>[];
    var query = await db.query(TichuTable.teamPlayers,
        where: 'player_id = ?', whereArgs: [playerId]);
    if (query.isEmpty) return result;

    for (var res in query) {
      result.add(await getFromId(res['team_id'] as int));
    }
    return result;
  }

  Future _insertPlayers(int teamId, List<int> playerIds,
      {bool clearExisting = false}) async {
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
  Future<Team> _populate(Team model) async {
    var result = model;
    if (model.id != null) {
      model.players = await _players(model.id as int);
    }
    return result;
  }

  @override
  Future<Team> insert(Team model, {bool notifyChange = true}) async {
    var result = await super.insert(model, notifyChange: notifyChange);
    await _insertPlayers(result.id!, result.playerIds);
    return result;
  }

  @override
  Future<Team> update(Team model, {bool notifyChange = true}) async {
    var result = await super.update(model, notifyChange: notifyChange);
    await _insertPlayers(result.id!, result.playerIds, clearExisting: true);
    return model;
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange = true}) async {
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
  @override
  String get table => TichuTable.game;
  List<Game> cachedGames = [];
  int changeCount = 0;

  GameRepository(super.db, super.repos);

  @override
  Game model() {
    return Game();
  }

  @override
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
  Future<Game> _populate(Game model) async {
    var teams = await repos.gameTeams.getFromGameId(model.id!);
    assert(teams.length == 2);
    model.team1 = teams[0];
    model.team2 = teams[1];
    return model;
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
  Future<Game> update(Game model, {bool notifyChange = true}) async {
    await super.update(model, notifyChange: false);
    await repos.gameTeams.update(model.team1);
    await repos.gameTeams.update(model.team2);
    await onDataChange();
    return model;
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange = true}) async {
    await repos.gameTeams.purgeGame(id);
    await repos.rounds.purgeGame(id);
    return await super.deleteFromId(id, notifyChange: notifyChange);
  }
}

class GameTeamRepository extends TichuRepo<GameTeam> {
  @override
  String get table => TichuTable.gameTeam;

  GameTeamRepository(super.db, super.repos);

  @override
  GameTeam model() {
    return GameTeam();
  }

  @override
  GameTeam hydratedModel(Map<String, dynamic> map) {
    return GameTeam.fromMap(map);
  }

  @override
  Future<GameTeam> _populate(GameTeam model) async {
    var result = model;
    if (result.teamId != null) {
      model.team = await repos.teams.getFromId(result.teamId!);
    }
    return model;
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
  Future<GameTeam> update(GameTeam model, {bool notifyChange = true}) async {
    var result = await super.update(model, notifyChange: false);
    if (result.team != null) {
      await repos.teams.update(result.team!);
    }
    onDataChange();
    return result;
  }

  Future<void> purgeGame(int id) async {
    var query = await db.query(table, where: 'game_id = ?', whereArgs: [id]);
    for (var gameTeam in query) {
      await deleteFromId(gameTeam['id'] as int);
    }
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange = true}) async {
    var gameTeam = await getFromId(id);
    if (gameTeam.teamId != null) {
      await repos.teams.deleteFromId(gameTeam.teamId!);
    }
    return await super.deleteFromId(id, notifyChange: notifyChange);
  }
}

class RoundRepository extends TichuRepo<Round> {
  @override
  String get table => TichuTable.round;

  RoundRepository(super.db, super.repos);

  @override
  Round model() {
    return Round();
  }

  @override
  Round hydratedModel(Map<String, dynamic> map) {
    return Round.fromMap(map);
  }

  @override
  Future<Round> _populate(Round model) async {
    var scores = await repos.scores.getWhere(
      where: 'round_id = ?',
      whereArgs: [model.id],
    );
    assert(scores.length == 2);
    if (scores[0].gameTeamId != null) {
      model.scores[scores[0].gameTeamId!] = scores[0];
    }
    if (scores[1].gameTeamId != null) {
      model.scores[scores[1].gameTeamId!] = scores[1];
    }
    return model;
  }

  @override
  Future<Round> insert(Round model, {bool notifyChange = true}) async {
    var newRound = await super.insert(model);
    for (int i in newRound.scores.keys) {
      var score = newRound.scores[i];
      if (score != null) {
        score.roundId = newRound.id;
        newRound.scores[i] = await repos.scores.insert(score);
      }
    }
    return newRound;
  }

  @override
  Future<Round> update(Round model, {bool notifyChange = true}) async {
    var updatedRound = await super.update(model, notifyChange: false);
    await repos.scores.purgeRound(model.id!);
    for (int i in updatedRound.scores.keys) {
      var score = updatedRound.scores[i];
      if (score != null) {
        score.roundId = updatedRound.id;
        updatedRound.scores[i] = await repos.scores.insert(score);
      }
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
      await deleteFromId(round['id'] as int);
    }
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange = true}) async {
    await repos.scores.purgeRound(id);
    return await super.deleteFromId(id, notifyChange: notifyChange);
  }
}

class ScoreRepository extends TichuRepo<Score> {
  @override
  String get table => TichuTable.score;

  ScoreRepository(super.db, super.repos);

  @override
  Future<Score> _populate(Score model) async {
    var result = model;
    if (result.id != null) {
      result.calls = await repos.calls.getFromScoreId(result.id!);
    }
    return result;
  }

  @override
  Score model() {
    return Score();
  }

  @override
  Score hydratedModel(Map<String, dynamic> map) {
    return Score.fromMap(map);
  }

  @override
  Future<Score> insert(Score model, {bool notifyChange = true}) async {
    var newScore = await super.insert(model);
    for (var i = 0; i < model.calls.length; i++) {
      newScore.calls[i].scoreId = newScore.id;
      newScore.calls[i] = await repos.calls.insert(newScore.calls[i]);
    }
    return newScore;
  }

  Future<void> purgeRound(int roundId) async {
    var query =
        await db.query(table, where: 'round_id = ?', whereArgs: [roundId]);
    for (var score in query) {
      await deleteFromId(score['id'] as int);
    }
  }

  @override
  Future<bool> deleteFromId(int id, {bool notifyChange = true}) async {
    await repos.calls.purgeScore(id);
    return await super.deleteFromId(id, notifyChange: notifyChange);
  }
}

class CallRepository extends TichuRepo<Call> {
  @override
  String get table => TichuTable.call;

  CallRepository(super.db, super.repos);

  @override
  Call model() {
    return Call();
  }

  @override
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
      await deleteFromId(call['id'] as int);
    }
  }
}
