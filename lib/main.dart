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
    return Row(children: [
      Expanded(
          child: TextFormField(
        autofocus: true,
        decoration: InputDecoration(
            icon: Icon(Octicons.getIconData("mark-github")),
            hintText: 'Please enter your ID.',
            labelText: 'GitHub User ID',
            helperText: ''),
        controller: _textController,
        validator: (value) {
          if (value.isEmpty) return 'Required!';
        },
        onEditingComplete: () {
          _submitID();
        },
      )),
      RaisedButton(
        onPressed: () {
          _submitID();
        },
        child: Text('Submit!'),
      )
    ]);
  }

  void _submitID() {
    if (_formKey.currentState.validate()) {
      FocusScope.of(context).requestFocus(FocusNode());
      _refreshContribList(_textController.text);
    }
  }

  Future<List<Contrib>> _getContribList(String userID) async {
    final response =
        await http.get("https://github-contributions-api.now.sh/v1/" + userID);
    final contribJson =
        jsonDecode(response.body)['contributions'].cast<Map<String, dynamic>>();
    final contribList =
        contribJson.map<Contrib>((json) => Contrib.fromJson(json)).toList();
    final today = DateTime.now();
    contribList.removeWhere((Contrib item) => item.date.compareTo(today) > 0);

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
              FocusScope.of(context).requestFocus(FocusNode());

              var contribCntStr = contribList[index].count.toString();
              if (contribList[index].count == 0) contribCntStr = 'no';

              var contribText = 'contribution';
              if (contribList[index].count != 1) contribText += 's';

              final snackBarText = RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: "$contribCntStr $contribText",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        " on ${DateFormat.yMMMd().format(contribList[index].date)}")
              ]));

              var s = Scaffold.of(context);
              s.hideCurrentSnackBar();
              s.showSnackBar(SnackBar(content: snackBarText));
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
