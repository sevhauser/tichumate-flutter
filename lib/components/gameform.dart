import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/models.dart';

class GameForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final FormFieldSetter<String> ruleCallback;
  final FormFieldSetter<int> winScoreCallback;
  final Game game;

  GameForm(
      {@required this.formKey,
      @required this.ruleCallback,
      @required this.winScoreCallback,
      @required this.game,
      Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        child: Column(
          children: <Widget>[
            _GameRuleSelect(
              onSaved: ruleCallback,
              initialValue: game.rule,
              context: context,
            ),
            TextFormField(
              decoration: InputDecoration(
                  labelText:
                      FlutterI18n.translate(context, 'game.rules.points')),
              onSaved: (value) => winScoreCallback(int.parse(value)),
              initialValue: game.winScore.toString(),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value.isEmpty) {
                  return FlutterI18n.translate(
                      context, 'ui.errors.provide_value');
                }
                try {
                  int.parse(value);
                } catch (e) {
                  return FlutterI18n.translate(
                      context, 'ui.errors.full_numbers_only');
                }
                return null;
              },
            ),
          ],
        ));
  }
}

class _GameRuleSelect extends FormField<String> {
  _GameRuleSelect({
    @required FormFieldSetter<String> onSaved,
    @required String initialValue,
    @required BuildContext context,
  }) : super(
            onSaved: onSaved,
            initialValue: initialValue,
            builder: (FormFieldState<String> state) {
              return InputDecorator(
                  decoration: InputDecoration(
                      labelText: FlutterI18n.translate(
                          context, 'game.rules.win_condition')),
                  child: Column(
                    children: <Widget>[
                      RadioListTile(
                        activeColor: Theme.of(context).accentColor,
                        groupValue: state.value,
                        title: Text(
                            FlutterI18n.translate(context, 'game.rules.score')),
                        value: GameRules.score,
                        onChanged: (value) => state.didChange(GameRules.score),
                      ),
                      RadioListTile(
                        activeColor: Theme.of(context).accentColor,
                        groupValue: state.value,
                        title: Text(FlutterI18n.translate(
                            context, 'game.rules.difference')),
                        value: GameRules.difference,
                        onChanged: (value) =>
                            state.didChange(GameRules.difference),
                      ),
                    ],
                  ));
            });
}
