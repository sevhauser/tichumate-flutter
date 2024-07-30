import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/state/models.dart';
import 'package:tichumate/dialogs/player.dart';

class TeamForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final FormFieldSetter<String> teamNameCallback;
  final FormFieldSetter<List<Player>> playersCallback;
  final List<Player>? secondaryPlayers;
  final Team team;

  const TeamForm(
      {required this.formKey,
      required this.team,
      required this.teamNameCallback,
      required this.playersCallback,
      this.secondaryPlayers,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(
                  labelText: FlutterI18n.translate(context, 'team.team_name')),
              initialValue: team.name,
              onSaved: teamNameCallback,
            ),
            TeamPlayersSelect(
              context: context,
              initialValue: team.players,
              onSaved: playersCallback,
              secondaryPlayers: secondaryPlayers ?? List.empty(),
            ),
          ],
        ));
  }
}

class TeamPlayersSelect extends FormField<List<Player>> {
  static List<Player> _addPlayerToList(List<Player> list, Player player) {
    list.add(player);
    return list;
  }

  TeamPlayersSelect(
      {required BuildContext context,
      required FormFieldSetter<List<Player>> onSaved,
      required List<Player> initialValue,
      required List<Player> secondaryPlayers,
      super.key})
      : super(
            onSaved: onSaved,
            initialValue: initialValue,
            builder: (FormFieldState<List<Player>> state) {
              var value = state.value ?? List.empty();
              return Column(children: <Widget>[
                Container(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          flex: 1,
                          fit: FlexFit.tight,
                          child: InputDecorator(
                              decoration: InputDecoration(
                                  labelText: FlutterI18n.translate(
                                      context, 'player.players')),
                              child: Wrap(
                                spacing: 5,
                                children: value.isEmpty
                                    ? [
                                        Text(FlutterI18n.translate(
                                            context, 'player.no_players'))
                                      ]
                                    : value
                                        .map((player) => InputChip(
                                              avatar: Text(player.icon),
                                              label: Text(player.name),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onDeleted: () => state.didChange(
                                                  value
                                                      .where((item) =>
                                                          item != player)
                                                      .toList()),
                                            ))
                                        .toList(),
                              )),
                        ),
                        Container(
                          padding: const EdgeInsets.only(top: 18),
                          child: IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () async {
                                var result = await PlayerDialog(context)
                                    .selectPlayer(value,
                                        secondary: secondaryPlayers);
                                if (result == null || result.id == null) {
                                  if (!context.mounted) return;
                                  result =
                                      await PlayerDialog(context).newPlayer();
                                }
                                if (result != null) {
                                  state.didChange(
                                      _addPlayerToList(value, result));
                                }
                              }),
                        ),
                      ],
                    ))
              ]);
            });
}
