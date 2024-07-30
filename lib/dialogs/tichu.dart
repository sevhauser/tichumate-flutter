import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:tichumate/state/database.dart';
import 'package:tichumate/state/models.dart';

class TichuDialog {
  final BuildContext context;
  TichuDialog(this.context);

  Future<Tichu?> createTichu() async {
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
                TextButton(
                  child: Text(FlutterI18n.translate(context, 'ui.cancel')
                      .toUpperCase()),
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
            ));
    if (shouldDelete != null && shouldDelete) {
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
  const _TichuForm(this.tichu) : super();

  @override
  _TichuFormState createState() => _TichuFormState();
}

class _TichuFormState extends State<_TichuForm> {
  final _formKey = GlobalKey<FormState>();
  _TichuFormState() : super();

  void _save() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      Navigator.of(context).pop(widget.tichu);
    }
  }

  @override
  Widget build(BuildContext context) {
    var tichu = widget.tichu;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 64,
          child: Center(
              child: Text(
            FlutterI18n.translate(context,
                'tichu.${tichu.id == null ? 'new_tichu' : 'edit_tichu'}'),
            style: const TextStyle(
              fontSize: 20,
            ),
          )),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                      labelText:
                          FlutterI18n.translate(context, 'tichu.tichu_name')),
                  initialValue: tichu.title,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return FlutterI18n.translate(
                          context, 'ui.errors.provide_name');
                    }
                    return null;
                  },
                  onSaved: (val) => setState(() => tichu.title = val!),
                ),
                TextFormField(
                  decoration: InputDecoration(
                      labelText: FlutterI18n.translate(context, 'ui.value')),
                  initialValue: tichu.id == null ? '' : tichu.value.toString(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
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
                    tichu.value = int.parse(val!);
                  }),
                )
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
        ),
      ],
    );
  }
}
