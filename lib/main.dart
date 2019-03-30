import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primarySwatch: Colors.lightGreen),
        home: Scaffold(
            appBar: AppBar(title: Text('Everyday Contrib')),
            body: ContribGrid()));
  }
}

class ContribGrid extends StatefulWidget {
  @override
  ContribState createState() => new ContribState();
}

class ContribState extends State<ContribGrid> {
  Future<List<Contrib>> _contribList;
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Form(
          key: _formKey,
          child: Row(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: TextFormField(
                // TODO placeholder
                controller: _textController,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter your GitHub user id.';
                  }
                },
              )),
              RaisedButton(
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    _refreshContribList(_textController.text);
                  }
                },
                child: Text('Submit'),
              ),
            ],
          )),
      Expanded(
          child: FutureBuilder<List<Contrib>>(
              future: _contribList,
              builder: (context, snapshot) {
                if (snapshot.hasError) print(snapshot.error);

                return snapshot.hasData
                    ? GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7),
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, index) {
                          return Container(color: snapshot.data[index].color);
                        })
                    : Center(child: Text('Please enter your GitHub user id.'));
              }))
    ]);
  }

  Future<List<Contrib>> _getContribList(String userID) async {
    final response =
        await http.get("https://github-contributions-api.now.sh/v1/" + userID);
    final contribJson =
        jsonDecode(response.body)['contributions'].cast<Map<String, dynamic>>();
    final contribList =
        contribJson.map<Contrib>((json) => Contrib.fromJson(json)).toList();
    contribList
        .removeWhere((Contrib item) => item.date.compareTo(DateTime.now()) > 0);

    final today = DateTime.now();
    if (today.weekday != DateTime.saturday) {
      var cnt = 6 - today.weekday;
      if (today.weekday == DateTime.sunday) {
        cnt = 6;
      }

      final ec = Contrib(date: today, count: 0, color: Colors.white);
      final insertList = new List<Contrib>.filled(cnt, ec);
      contribList.insertAll(0, insertList);
    }

    return contribList;
  }

  void _refreshContribList(String userID) async {
    setState(() {
      _contribList = _getContribList(userID);
    });
  }
}

class Contrib {
  final DateTime date;
  final int count;
  final Color color;

  Contrib({this.date, this.count, this.color});

  factory Contrib.fromJson(Map<String, dynamic> json) {
    return Contrib(
        date: DateTime.parse(json['date']),
        count: json['count'] as int,
        color: Color(
            int.parse(json['color'].replaceAll(new RegExp(r'#'), '0xFF'))));
  }
}
