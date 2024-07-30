import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:tichumate/components/fab.dart';

import 'package:tichumate/components/gameheader.dart';
import 'package:tichumate/dialogs/player.dart';
import 'package:tichumate/dialogs/tichu.dart';
import 'package:tichumate/state/database.dart';
import 'package:tichumate/state/models.dart';
import 'package:tichumate/views/game.dart';

class HomeData extends InheritedWidget {
  final int playersChange, gamesChange, tichusChange;
  final List<Player> players;
  final List<Game> games;
  final List<Tichu> tichus;

  const HomeData({
    required this.players,
    required this.games,
    required this.tichus,
    required this.playersChange,
    required this.gamesChange,
    required this.tichusChange,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(HomeData oldWidget) {
    var result = (playersChange != oldWidget.playersChange ||
        gamesChange != oldWidget.gamesChange ||
        tichusChange != oldWidget.tichusChange);
    return result;
  }

  static HomeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeData>() as HomeData;
  }
}

class HomeView extends StatefulWidget {
  final int initialIndex;
  const HomeView({super.key, this.initialIndex = 1});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  static const tabStyle = TextStyle(
    fontFamily: 'RobotoCondensed',
    fontSize: 16,
  );

  _HomeViewState() : super();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        vsync: this, length: 3, initialIndex: widget.initialIndex);
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
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
        centerTitle: true,
        toolbarHeight: 48,
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
        shape: null,
      ),
      body: HomeData(
        players: TichuDB().players.players,
        playersChange: TichuDB().players.changeCount,
        games: TichuDB().games.cachedGames,
        gamesChange: TichuDB().games.changeCount,
        tichus: TichuDB().tichus.cachedTichus,
        tichusChange: TichuDB().tichus.changeCount,
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[
            _PlayersTab(),
            _GamesTab(),
            _CustomizeTab(),
          ],
        ),
      ),
    );
  }
}

class _GamesTab extends StatelessWidget {
  List<Widget> _gamesList(BuildContext context) {
    var list = <Widget>[];
    var dateFormatter = DateFormat.yMMMMd();
    String? currentDate;
    var games = HomeData.of(context).games;
    for (var item in games) {
      if (currentDate != dateFormatter.format(item.createdOn)) {
        currentDate = dateFormatter.format(item.createdOn);
        list.add(Container(
          color: Theme.of(context).colorScheme.surfaceDim,
          padding: const EdgeInsets.all(5),
          child: Center(child: Text(currentDate)),
        ));
      }
      list.add(InkWell(
        onTap: () => Navigator.of(context)
            .pushNamed('/game', arguments: GameViewArguments(gameId: item.id!)),
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
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    var gamesList = _gamesList(context);
    return Scaffold(
      body: ListView.separated(
        itemCount: gamesList.length,
        itemBuilder: (context, index) => gamesList[index],
        separatorBuilder: (context, index) {
          var isContainer = gamesList[index] is Container;
          var beforeContainer =
              index < gamesList.length - 1 && gamesList[index + 1] is Container;
          if (isContainer || beforeContainer) {
            return Container();
          }
          return const Divider();
        },
      ),
      floatingActionButton: ExtendedFab(
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
  List<Widget> _playersList(BuildContext context) {
    var players = HomeData.of(context).players;
    var list = <Widget>[];
    var currentLetter = '';

    for (var item in players) {
      if (currentLetter != item.name[0].toUpperCase()) {
        currentLetter = item.name[0].toUpperCase();
        list.add(Container(
          color: Theme.of(context).colorScheme.surfaceDim,
          padding: const EdgeInsets.all(5),
          child: Center(child: Text(currentLetter)),
        ));
      }
      list.add(ListTile(
        leading: Text(item.icon, style: const TextStyle(fontSize: 18)),
        title: Text(item.name),
        onTap: () => Navigator.of(context)
            .pushNamed('/player', arguments: {'playerId': item.id}),
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    var players = _playersList(context);
    return Scaffold(
      body: ListView.separated(
          itemCount: players.length,
          itemBuilder: (context, index) {
            return players[index];
          },
          separatorBuilder: (context, index) {
            var isContainer = players[index] is Container;
            var beforeContainer =
                index < players.length - 1 && players[index + 1] is Container;
            if (isContainer || beforeContainer) {
              return Container();
            }
            return const Divider();
          }),
      floatingActionButton: ExtendedFab(
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
  void _deleteTichu(BuildContext context, int id) async {
    var result = await TichuDialog(context).deleteTichu(id);
    if (!context.mounted) return;
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(FlutterI18n.translate(context, 'tichu.tichu_deleted')),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  List<Widget> _tichuList(BuildContext context) {
    var tichus = <Widget>[];
    var cachedTichus = HomeData.of(context).tichus;
    for (var item in cachedTichus) {
      var title = item.title;
      if (item.lang.isNotEmpty) {
        title = FlutterI18n.translate(context, '${item.lang}.title');
      }
      tichus.add(ListTile(
        title: Text(title),
        subtitle: Text(FlutterI18n.translate(context, 'tichu.x_points',
            translationParams: {'x': item.value.toString()})),
        leading: item.protected ? const Icon(Icons.lock) : const Text(''),
        trailing: item.protected
            ? const Text('')
            : PopupMenuButton(
                onSelected: (_TichuOptions result) {
                  if (result == _TichuOptions.edit) {
                    TichuDialog(context).editTichu(item.id!);
                  } else if (result == _TichuOptions.delete) {
                    _deleteTichu(context, item.id!);
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
                          style: TextStyle(color: Colors.red.shade500)))
                ],
              ),
      ));
    }
    return tichus;
  }

  @override
  Widget build(BuildContext context) {
    var tichus = _tichuList(context);
    return Scaffold(
      body: ListView.separated(
        separatorBuilder: (context, index) => const Divider(),
        itemCount: tichus.length,
        itemBuilder: (context, index) => tichus[index],
      ),
      floatingActionButton: ExtendedFab(
        heroTag: 'home-new-tichu',
        onPressed: () => TichuDialog(context).createTichu(),
        label: Text(
            FlutterI18n.translate(context, 'tichu.new_tichu').toUpperCase()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
