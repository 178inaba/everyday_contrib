import 'dart:async';
import 'dart:convert';

import 'package:flutter_icons/flutter_icons.dart';
import 'package:intl/intl.dart';
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
            body: ContribWidget()));
  }
}

class ContribWidget extends StatefulWidget {
  @override
  ContribWidgetState createState() => ContribWidgetState();
}

class ContribWidgetState extends State<ContribWidget> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  Widget _contribSection = Container();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Form(key: _formKey, child: _idInputRow()),
      Expanded(child: _contribSection)
    ]);
  }

  Row _idInputRow() {
    return Row(
      children: [
        Expanded(
            child: TextFormField(
          decoration: InputDecoration(
              icon: Icon(Octicons.getIconData("mark-github")),
              hintText: 'Please enter your ID.',
              labelText: 'GitHub User ID',
              helperText: ''),
          controller: _textController,
          validator: (value) {
            if (value.isEmpty) return 'Required!';
          },
        )),
        RaisedButton(
          onPressed: () {
            if (_formKey.currentState.validate())
              _refreshContribList(_textController.text);
          },
          child: Text('Submit'),
        ),
      ],
    );
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
      if (today.weekday == DateTime.sunday) cnt = 6;

      final insertList = List<Contrib>.filled(cnt, Contrib());
      contribList.insertAll(0, insertList);
    }

    return contribList;
  }

  void _refreshContribList(String userID) async {
    setState(() {
      _contribSection = FutureBuilder<List<Contrib>>(
          future: _getContribList(userID),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text(snapshot.error));

            if (snapshot.connectionState == ConnectionState.done)
              return _getContribGrid(snapshot.data);

            return Center(child: CircularProgressIndicator());
          });
    });
  }

  GridView _getContribGrid(List<Contrib> contribList) {
    return GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
        itemCount: contribList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              var s = Scaffold.of(context);
              s.hideCurrentSnackBar();
              s.showSnackBar(SnackBar(
                content: Text(
                    "${contribList[index].count} contributions on ${DateFormat.yMMMd().format(contribList[index].date)}"),
              ));
            },
            child: Container(
                color: contribList[index].color, margin: EdgeInsets.all(3)),
          );
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
        color:
            Color(int.parse(json['color'].replaceAll(RegExp(r'#'), '0xFF'))));
  }
}
