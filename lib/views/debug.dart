import 'package:flutter/material.dart';

import 'package:tichumate/database.dart';

class DataDebugView extends StatefulWidget {
  @override
  _DataDebugViewContent createState() => _DataDebugViewContent();
}

class _DataDebugViewContent extends State<DataDebugView> {
  TichuDB _db = TichuDB();
  String display = TichuTable.player;
  DataTable table;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadDisplay();
  }

  void _setDisplay(String value) {
    display = value;
    _loadDisplay();
  }

  Future<void> _loadDisplay() async {
    var query = await _db.db.query(display);
    var columns = TichuTable.columns[display]
        .map((el) => DataColumn(label: Text(el)))
        .toList();
    var rows = <DataRow>[];
    query.forEach((q) {
      var cells = <DataCell>[];
      TichuTable.columns[display].forEach((c) {
        cells.add(DataCell(Text(q[c].toString())));
      });
      rows.add(DataRow(
        cells: cells,
      ));
    });
    setState(() {
      _loaded = true;
      table = DataTable(
        columns: columns,
        rows: rows,
      );
    });
  }

  Widget _colSelection() {
    return Row(
      children: <Widget>[
        Spacer(),
        DropdownButton(
            value: display,
            items: TichuTable.columns.keys
                .map((k) => DropdownMenuItem(
                      child: Text(k),
                      value: k,
                    ))
                .toList(),
            onChanged: _setDisplay)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DEBUG'),
      ),
      body: _loaded
          ? ListView(scrollDirection: Axis.vertical, children: [
              Container(child: _colSelection()),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              )
            ])
          : Container(),
    );
  }
}
