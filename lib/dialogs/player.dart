import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter/rendering.dart';

import 'package:tichumate/database.dart';
import 'package:tichumate/models.dart';

class PlayerDialog {
  final BuildContext context;
  PlayerDialog(this.context);

  Future<Player> newPlayer() async {
    var newPlayer = await _showEditDialog(Player());
    return newPlayer.id == null ? null : newPlayer;
  }

  Future<Player> editPlayer(int id) async {
    var player = await TichuDB().players.getFromId(id);
    await _showEditDialog(player);
    return player;
  }

  Future<bool> deletePlayer(int id) async {
    var player = await TichuDB().players.getFromId(id);
    var shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(FlutterI18n.translate(
            context, 'ui.delete_target', {'target': player.name})),
        content:
            Text(FlutterI18n.translate(context, 'ui.this_cannot_be_undone')),
        actions: <Widget>[
          FlatButton(
            child:
                Text(FlutterI18n.translate(context, 'ui.cancel').toUpperCase()),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          FlatButton(
            child: Text(
              FlutterI18n.translate(context, 'ui.delete').toUpperCase(),
              style: TextStyle(color: Colors.red[500]),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    if (shouldDelete) {
      return await TichuDB().players.deleteFromId(id);
    }
    return false;
  }

  Future<Player> selectPlayer(List<Player> exclude,
      {List<Player> secondary}) async {
    var players = List<Player>.from(TichuDB().players.players);
    if (exclude != null) {
      players.removeWhere((player) => exclude.any((p) => p.id == player.id));
    }
    var playerList = players.map((player) {
      bool _secondary =
          secondary == null ? false : secondary.any((p) => p.id == player.id);
      return SimpleDialogOption(
        child: Row(
          children: <Widget>[
            Container(
              child: Text(
                player.icon,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              padding: EdgeInsets.only(right: 11, left: 1),
            ),
            Text(player.name,
                style: TextStyle(
                    color: _secondary ? Colors.white30 : Colors.white))
          ],
        ),
        onPressed: () => Navigator.of(context).pop(player),
      );
    }).toList();
    playerList.add(SimpleDialogOption(
      child: Row(
        children: <Widget>[
          Container(
            child: Icon(Icons.add_circle),
            padding: EdgeInsets.only(right: 10),
          ),
          Text(
              FlutterI18n.translate(context, 'player.new_player').toUpperCase())
        ],
      ),
      onPressed: () => Navigator.of(context).pop(Player()),
    ));
    var result = await showDialog<Player>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(FlutterI18n.translate(context, 'player.choose_player')),
        children: playerList,
      ),
    );
    return result;
  }

  Future<Player> _showEditDialog(Player player) async {
    final isNew = player.id == null;
    var result = await showDialog<Player>(
      context: context,
      builder: (context) => Dialog(
        child: _PlayerForm(player),
      ),
    );
    if (result == null) {
      return player;
    } else if (isNew) {
      return await TichuDB().players.insert(result);
    }
    return await TichuDB().players.update(result);
  }
}

class _PlayerForm extends StatefulWidget {
  final Player player;
  _PlayerForm(this.player) : super();

  @override
  _PlayerFormState createState() => _PlayerFormState(player);
}

class _PlayerFormState extends State<_PlayerForm> {
  Player player;
  final _formKey = GlobalKey<FormState>();
  _PlayerFormState(this.player) : super();

  void _save() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      Navigator.of(context).pop(player);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          child: Center(
              child: Text(
            FlutterI18n.translate(context,
                'player.${player.id == null ? 'new_player' : 'edit_player'}'),
            style: TextStyle(
              fontSize: 20,
            ),
          )),
          height: 64,
        ),
        Container(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Flexible(
                  child: TextFormField(
                    decoration: InputDecoration(
                        labelText: FlutterI18n.translate(
                            context, 'player.player_name')),
                    initialValue: player.name,
                    validator: (value) {
                      if (value.isEmpty) {
                        return FlutterI18n.translate(
                            context, 'ui.errors.provide_name');
                      }
                      return null;
                    },
                    onSaved: (val) => setState(() => player.name = val),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: 10, left: 10),
                  child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                    value: player.icon,
                    isDense: true,
                    underline: Container(height: 1),
                    items: emojiList
                        .map((emoji) => DropdownMenuItem(
                              child: Center(child: Text(emoji)),
                              value: emoji,
                            ))
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        player.icon = newValue;
                      });
                    },
                  )),
                ),
              ],
            ),
          ),
        ),
        ButtonTheme.bar(
            child: ButtonBar(
          children: <Widget>[
            FlatButton(
              child: Text(
                FlutterI18n.translate(context, 'ui.cancel').toUpperCase(),
                style: TextStyle(color: Theme.of(context).accentColor),
              ),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            FlatButton(
              child: Text(
                FlutterI18n.translate(context, 'ui.save').toUpperCase(),
                style: TextStyle(color: Colors.greenAccent[400]),
              ),
              onPressed: () => _save(),
            ),
          ],
        ))
      ],
    );
  }
}

final List<String> emojiList = [
  '😀',
  '😁',
  '😂',
  '🤣',
  '😃',
  '😄',
  '😅',
  '😆',
  '😉',
  '😊',
  '😋',
  '😎',
  '😍',
  '😘',
  '🥰',
  '😗',
  '😙',
  '😚',
  '☺',
  '🙂',
  '🤗',
  '🤩',
  '🤔',
  '🤨',
  '😐',
  '😑',
  '😶',
  '🙄',
  '😏',
  '😣',
  '😥',
  '😮',
  '🤐',
  '😯',
  '😪',
  '😫',
  '😴',
  '😌',
  '😛',
  '😜',
  '😝',
  '🤤',
  '😒',
  '😓',
  '😔',
  '😕',
  '🙃',
  '🤑',
  '😲',
  '☹',
  '🙁',
  '😖',
  '😞',
  '😟',
  '😤',
  '😢',
  '😭',
  '😦',
  '😧',
  '😨',
  '😩',
  '🤯',
  '😬',
  '😰',
  '😱',
  '🥵',
  '🥶',
  '😳',
  '🤪',
  '😵',
  '😡',
  '😠',
  '🤬',
  '😷',
  '🤒',
  '🤕',
  '🤢',
  '🤮',
  '🤧',
  '😇',
  '🤠',
  '🥳',
  '🥴',
  '🥺',
  '🤥',
  '🤫',
  '🤭',
  '🧐',
  '🤓',
  '😈',
  '👿',
  '🤡',
  '👹',
  '👺',
  '💀',
  '☠',
  '👻',
  '👽',
  '👾',
  '🤖',
  '💩',
  '😺',
  '😸',
  '😹',
  '😻',
  '😼',
  '😽',
  '🙀',
  '😿',
  '😾',
  '🙈',
  '🙉',
  '🙊',
  '👶',
  '🧒',
  '👦',
  '👧',
  '🧑',
  '👨',
  '👩',
  '🧓',
  '👴',
  '👵',
  '👨‍⚕️',
  '👩‍⚕️',
  '👨‍🎓',
  '👩‍🎓',
  '👨‍🏫',
  '👩‍🏫',
  '👨‍⚖️',
  '👩‍⚖️',
  '👨‍🌾',
  '👩‍🌾',
  '👨‍🍳',
  '👩‍🍳',
  '👨‍🔧',
  '👩‍🔧',
  '👨‍🏭',
  '👩‍🏭',
  '👨‍💼',
  '👩‍💼',
  '👨‍🔬',
  '👩‍🔬',
  '👨‍💻',
  '👩‍💻',
  '👨‍🎤',
  '👩‍🎤',
  '👨‍🎨',
  '👩‍🎨',
  '👨‍✈️',
  '👩‍✈️',
  '👨‍🚀',
  '👩‍🚀',
  '👨‍🚒',
  '👩‍🚒',
  '👮',
  '🕵',
  '💂',
  '👷',
  '🤴',
  '👸',
  '👳',
  '👲',
  '🧕',
  '🧔',
  '👱',
  '🤵',
  '👰',
  '🤰',
  '🤱',
  '👼',
  '🎅',
  '🤶'
];
