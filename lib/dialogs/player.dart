import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/state/database.dart';
import 'package:tichumate/state/models.dart';

class PlayerDialog {
  final BuildContext context;
  PlayerDialog(this.context);

  Future<Player?> newPlayer() async {
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
    if (!context.mounted) return false;
    var shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(FlutterI18n.translate(context, 'ui.delete_target',
            translationParams: {'target': player.name})),
        content:
            Text(FlutterI18n.translate(context, 'ui.this_cannot_be_undone')),
        actions: <Widget>[
          TextButton(
            child:
                Text(FlutterI18n.translate(context, 'ui.cancel').toUpperCase()),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text(
              FlutterI18n.translate(context, 'ui.delete').toUpperCase(),
              style: TextStyle(color: Colors.red.shade500),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    if (shouldDelete != null && shouldDelete) {
      return await TichuDB().players.deleteFromId(id);
    }
    return false;
  }

  Future<Player?> selectPlayer(List<Player> exclude,
      {List<Player>? secondary}) async {
    var players = List<Player>.from(TichuDB().players.players);
    players.removeWhere((player) => exclude.any((p) => p.id == player.id));
    var playerList = players.map((player) {
      bool isSecondary =
          secondary == null ? false : secondary.any((p) => p.id == player.id);
      return SimpleDialogOption(
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(right: 11, left: 1),
              child: Text(
                player.icon,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            Text(player.name,
                style: TextStyle(
                    color: isSecondary ? Colors.white30 : Colors.white))
          ],
        ),
        onPressed: () => Navigator.of(context).pop(player),
      );
    }).toList();
    playerList.add(SimpleDialogOption(
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(right: 10),
            child: const Icon(Icons.add_circle),
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
  const _PlayerForm(this.player) : super();

  @override
  _PlayerFormState createState() => _PlayerFormState();
}

class _PlayerFormState extends State<_PlayerForm> {
  final _formKey = GlobalKey<FormState>();
  _PlayerFormState() : super();

  void _save() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      Navigator.of(context).pop(widget.player);
    }
  }

  @override
  Widget build(BuildContext context) {
    var player = widget.player;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 64,
          child: Center(
              child: Text(
            FlutterI18n.translate(context,
                'player.${player.id == null ? 'new_player' : 'edit_player'}'),
            style: const TextStyle(
              fontSize: 20,
            ),
          )),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
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
                      if (value != null && value.isEmpty) {
                        return FlutterI18n.translate(
                            context, 'ui.errors.provide_name');
                      }
                      return null;
                    },
                    onSaved: (val) => setState(() => player.name = val!),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 10, left: 10),
                  child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                    value: player.icon,
                    isDense: true,
                    underline: Container(height: 1),
                    items: emojiList
                        .map((emoji) => DropdownMenuItem(
                              value: emoji,
                              child: Center(child: Text(emoji)),
                            ))
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        if (newValue != null) {
                          player.icon = newValue;
                        }
                      });
                    },
                  )),
                ),
              ],
            ),
          ),
        ),
        OverflowBar(
          alignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              child: Text(
                FlutterI18n.translate(context, 'ui.cancel').toUpperCase(),
                style: TextStyle(color: Colors.amber.shade400),
              ),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            TextButton(
              child: Text(
                FlutterI18n.translate(context, 'ui.save').toUpperCase(),
                style: TextStyle(color: Colors.greenAccent.shade400),
              ),
              onPressed: () => _save(),
            ),
          ],
        )
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
