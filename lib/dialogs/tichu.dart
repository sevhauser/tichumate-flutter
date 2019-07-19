import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:tichumate/database.dart';
import 'package:tichumate/models.dart';

class TichuDialog {
  final BuildContext context;
  TichuDialog(this.context);

  Future<Tichu> createTichu() async {
    var newTichu = await _showEditDialog(Tichu());
    return newTichu.id == null ? null : newTichu;
  }

  Future<Tichu> editTichu(int id) async {
    var tichu = await TichuDB().tichus.getFromId(id);
    await _showEditDialog(tichu);
    return tichu;
  }

  Future<bool> deleteTichu(int id) async {
    var shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(FlutterI18n.translate(context, 'tichu.delete_tichu')),
              actions: <Widget>[
                FlatButton(
                  child: Text(FlutterI18n.translate(context, 'ui.cancel')
                      .toUpperCase()),
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
            ));
    if (shouldDelete) {
      return await TichuDB().tichus.deleteFromId(id);
    }
    return false;
  }

  Future<Tichu> _showEditDialog(Tichu tichu) async {
    final isNew = tichu.id == null;
    var result = await showDialog<Tichu>(
      context: context,
      builder: (context) => Dialog(
        child: _TichuForm(tichu),
      ),
    );
    if (result == null) {
      return tichu;
    } else if (isNew) {
      return await TichuDB().tichus.insert(result);
    }
    return await TichuDB().tichus.update(result);
  }
}

class _TichuForm extends StatefulWidget {
  final Tichu tichu;
  _TichuForm(this.tichu) : super();

  @override
  _TichuFormState createState() => _TichuFormState(tichu);
}

class _TichuFormState extends State<_TichuForm> {
  Tichu tichu;
  final _formKey = GlobalKey<FormState>();
  _TichuFormState(this.tichu) : super();

  void _save() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      Navigator.of(context).pop(tichu);
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
                'tichu.${tichu.id == null ? 'new_tichu' : 'edit_tichu'}'),
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
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                      labelText:
                          FlutterI18n.translate(context, 'tichu.tichu_name')),
                  initialValue: tichu.title ?? '',
                  validator: (value) {
                    if (value.isEmpty) {
                      return FlutterI18n.translate(
                          context, 'ui.errors.provide_name');
                    }
                    return null;
                  },
                  onSaved: (val) => setState(() => tichu.title = val),
                ),
                TextFormField(
                  decoration: InputDecoration(
                      labelText: FlutterI18n.translate(context, 'ui.value')),
                  initialValue: tichu.id == null ? '' : tichu.value.toString(),
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
                  keyboardType: TextInputType.number,
                  onSaved: (val) => setState(() {
                    tichu.value = int.parse(val);
                  }),
                )
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
          ),
        )
      ],
    );
  }
}
