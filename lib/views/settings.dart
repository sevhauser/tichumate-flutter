import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:tichumate/components/tichumatelogo.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatelessWidget {
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'preferences.preferences')),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
              leading: TichuMateLogo(
                width: 24,
              ),
              isThreeLine: true,
              title: Text('TichuMate'),
              subtitle: Container(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(FlutterI18n.translate(context, 'about.about_text')),
              )),
          Divider(),
          ListTile(
            leading: Icon(Icons.feedback),
            isThreeLine: true,
            title: Text(FlutterI18n.translate(context, 'preferences.feedback')),
            subtitle:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: Text(FlutterI18n.translate(
                    context, 'preferences.feedback_text')),
              ),
              Row(children: [
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: RaisedButton(
                      child: Text('GitHub'),
                      color: Theme.of(context).accentColor,
                      textColor: Colors.black,
                      onPressed: () => _launchURL(
                          'https://github.com/sevhauser/tichumate-flutter'),
                    )),
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: RaisedButton(
                      child: Text('E-Mail'),
                      color: Theme.of(context).accentColor,
                      textColor: Colors.black,
                      onPressed: () => _launchURL(
                          'mailto:tiltedch@gmail.com?subject=TichuMate Feedback'),
                    )),
              ])
            ]),
          ),
          Divider(),
          AboutListTile(
            icon: Icon(Icons.help),
            applicationIcon: TichuMateLogo(
              width: 40,
            ),
            applicationVersion: FlutterI18n.translate(
                context, 'about.version_x', {'version': '0.1.0'}),
            applicationLegalese: 'Copyright 2019 Severin Hauser\n\n'
                'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n'
                'The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\n'
                'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
          ),
        ],
      ),
    );
  }
}
