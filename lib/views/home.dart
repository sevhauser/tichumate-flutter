import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/components/gameheader.dart';
import 'package:tichumate/database.dart';
import 'package:tichumate/dialogs/player.dart';
import 'package:tichumate/dialogs/tichu.dart';
import 'package:tichumate/models.dart';
import 'package:tichumate/views/game.dart';

class HomeView extends StatefulWidget {
  final int initialIndex;
  const HomeView({Key key, this.initialIndex: 1}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState(initialIndex);
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  static final tabStyle = TextStyle(
    fontFamily: 'RobotoCondensed',
    fontSize: 16,
  );
  final int initialIndex;

  _HomeViewState(this.initialIndex) : super();

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(vsync: this, length: 3, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: UniqueKey(),
        title: Image.asset(
          'assets/logo.png',
          height: 30,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
        centerTitle: true,
        bottom: TabBar(
          tabs: <Tab>[
            Tab(
                child: Text(
                    FlutterI18n.translate(context, 'player.players')
                        .toUpperCase(),
                    style: tabStyle)),
            Tab(
                child: Text(
                    FlutterI18n.translate(context, 'game.games').toUpperCase(),
                    style: tabStyle)),
            Tab(
                child: Text(
                    FlutterI18n.translate(context, 'customize.customize')
                        .toUpperCase(),
                    style: tabStyle)),
          ],
          controller: _tabController,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _PlayersTab(),
          _GamesTab(),
          _CustomizeTab(),
        ],
      ),
    );
  }
}

class _GamesTab extends StatelessWidget {
  final List<Game> _games = TichuDB().games.cachedGames;

  List<Widget> _gamesList(BuildContext context) {
    var list = <Widget>[];
    var dateFormatter = DateFormat.yMMMMd();
    String currentDate;

    _games.forEach((item) {
      if (currentDate != dateFormatter.format(item.createdOn)) {
        currentDate = dateFormatter.format(item.createdOn);
        list.add(Container(
          child: Center(child: Text(currentDate)),
          color: Colors.grey[900],
          padding: const EdgeInsets.all(5),
        ));
      }
      list.add(InkWell(
        onTap: () => Navigator.of(context)
            .pushNamed('/game', arguments: GameViewArguments(gameId: item.id)),
        child: GameSummary(
          compact: true,
          slots: <GameHeaderSlot>[
            GameHeaderSlot(
                players: item.team1.players,
                score: item.team1.score,
                teamName: item.team1.name,
                status: item.team1.win
                    ? GameHeaderSlotStatus.accent
                    : GameHeaderSlotStatus.neutral),
            GameHeaderSlot(
                players: item.team2.players,
                score: item.team2.score,
                teamName: item.team2.name,
                status: item.team2.win
                    ? GameHeaderSlotStatus.accent
                    : GameHeaderSlotStatus.neutral),
          ],
        ),
      ));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    var gamesList = _gamesList(context);
    return Scaffold(
      body: Container(
        child: ListView.separated(
          itemCount: gamesList.length,
          itemBuilder: (context, index) => gamesList[index],
          separatorBuilder: (context, index) {
            var isContainer = gamesList[index] is Container;
            var beforeContainer = index < gamesList.length - 1 &&
                gamesList[index + 1] is Container;
            if (isContainer || beforeContainer) {
              return Container();
            }
            return Divider();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home-new-game',
        label:
            Text(FlutterI18n.translate(context, 'game.new_game').toUpperCase()),
        onPressed: () => Navigator.pushNamed(context, '/newgame'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _PlayersTab extends StatelessWidget {
  final PlayerRepository _playerRepository = TichuDB().players;

  List<Widget> _playersList(BuildContext context) {
    var players = _playerRepository.players;
    var list = <Widget>[];
    var currentLetter = '';

    players.forEach((item) {
      if (currentLetter != item.name[0].toUpperCase()) {
        currentLetter = item.name[0].toUpperCase();
        list.add(Container(
          child: Center(child: Text(currentLetter)),
          color: Colors.grey[900],
          padding: const EdgeInsets.all(5),
        ));
      }
      list.add(ListTile(
        leading: Text(item.icon, style: TextStyle(fontSize: 18)),
        title: Text(item.name),
        onTap: () => Navigator.of(context)
            .pushNamed('/player', arguments: {'playerId': item.id}),
      ));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    var _players = _playersList(context);
    return Scaffold(
      body: ListView.separated(
          itemCount: _players.length,
          itemBuilder: (context, index) {
            return _players[index];
          },
          separatorBuilder: (context, index) {
            var isContainer = _players[index] is Container;
            var beforeContainer =
                index < _players.length - 1 && _players[index + 1] is Container;
            if (isContainer || beforeContainer) {
              return Container();
            }
            return Divider();
          }),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home-new-player',
        onPressed: () => PlayerDialog(context).newPlayer(),
        label: Text(
            FlutterI18n.translate(context, 'player.new_player').toUpperCase()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

enum _TichuOptions { edit, delete }

class _CustomizeTab extends StatelessWidget {
  final TichuRepository _tichuRepository = TichuDB().tichus;

  void _deleteTichu(BuildContext context, int id) async {
    var result = await TichuDialog(context).deleteTichu(id);
    if (result) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(FlutterI18n.translate(context, 'tichu.tichu_deleted')),
        duration: Duration(seconds: 1),
      ));
    }
  }

  List<Widget> _tichuList(BuildContext context) {
    var tichus = <Widget>[];
    _tichuRepository.cachedTichus.forEach((item) {
      var title = item.title;
      if (item.lang.isNotEmpty) {
        title = FlutterI18n.translate(context, item.lang + '.title');
      }
      tichus.add(ListTile(
        title: Text(title),
        subtitle: Text(FlutterI18n.translate(
            context, 'tichu.x_points', {'x': item.value.toString()})),
        leading: item.protected ? Icon(Icons.lock) : Text(''),
        trailing: item.protected
            ? Text('')
            : PopupMenuButton(
                onSelected: (_TichuOptions result) {
                  if (result == _TichuOptions.edit) {
                    TichuDialog(context).editTichu(item.id);
                  } else if (result == _TichuOptions.delete) {
                    _deleteTichu(context, item.id);
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<_TichuOptions>>[
                  PopupMenuItem<_TichuOptions>(
                    value: _TichuOptions.edit,
                    child: Text(FlutterI18n.translate(context, 'ui.edit')),
                  ),
                  PopupMenuItem<_TichuOptions>(
                      value: _TichuOptions.delete,
                      child: Text(FlutterI18n.translate(context, 'ui.delete'),
                          style: TextStyle(color: Colors.red[500])))
                ],
              ),
      ));
    });
    return tichus;
  }

  @override
  Widget build(BuildContext context) {
    var _tichus = _tichuList(context);
    return Scaffold(
      body: ListView.separated(
        separatorBuilder: (context, index) => Divider(),
        itemCount: _tichus.length,
        itemBuilder: (context, index) => _tichus[index],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home-new-tichu',
        onPressed: () => TichuDialog(context).createTichu(),
        label: Text(
            FlutterI18n.translate(context, 'tichu.new_tichu').toUpperCase()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
