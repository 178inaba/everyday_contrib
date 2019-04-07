import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
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
        body: ContribWidget(),
      ),
    );
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
  initState() {
    super.initState();
    _initWidget();
  }

  _initWidget() async {
    var prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('github_id');
    if ([null, ''].contains(id)) return;

    setState(() {
      _textController.text = id;
    });

    _refreshContribList(id);
  }

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
            helperText: '',
          ),
          controller: _textController,
          validator: (value) {
            if (value.isEmpty) return 'Required!';
          },
          onEditingComplete: () => _submitID(),
        ),
      ),
      RaisedButton(onPressed: () => _submitID(), child: Text('Submit!'))
    ]);
  }

  _submitID() async {
    if (!_formKey.currentState.validate()) return;

    FocusScope.of(context).requestFocus(FocusNode());

    final id = _textController.text;
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('github_id', id);
    _refreshContribList(id);
  }

  _refreshContribList(String userID) {
    setState(() {
      _contribSection = FutureBuilder<List<Contrib>>(
        future: _getContribList(userID),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(snapshot.error));

          if (snapshot.connectionState == ConnectionState.done)
            return _getContribGrid(snapshot.data);

          return Center(child: CircularProgressIndicator());
        },
      );
    });
  }

  GridView _getContribGrid(List<Contrib> contribList) {
    return GridView.builder(
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemCount: contribList.length,
      itemBuilder: (context, index) {
        final c = contribList[index];
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());

            final s = Scaffold.of(context);
            s.hideCurrentSnackBar();
            s.showSnackBar(SnackBar(content: _getSnackBarText(c)));
          },
          child: Container(color: c.color, margin: EdgeInsets.all(3)),
        );
      },
    );
  }

  RichText _getSnackBarText(Contrib c) {
    var contribCntStr = c.count.toString();
    if (c.count == 0) contribCntStr = 'no';

    var contribText = 'contribution';
    if (c.count != 1) contribText += 's';

    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: "$contribCntStr $contribText",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(text: " on ${DateFormat.yMMMd().format(c.date)}")
      ]),
    );
  }

  Future<List<Contrib>> _getContribList(String userID) async {
    final response =
        await http.get("https://github-contributions-api.now.sh/v1/" + userID);
    final contribList = jsonDecode(response.body)['contributions']
        .cast<Map<String, dynamic>>()
        .map<Contrib>((json) => Contrib.fromJson(json))
        .toList();
    final today = DateTime.now();
    contribList.removeWhere((Contrib item) => item.date.compareTo(today) > 0);

    if (today.weekday != DateTime.saturday) {
      var cnt = 6 - today.weekday;
      if (today.weekday == DateTime.sunday) cnt = 6;

      contribList.insertAll(0, List<Contrib>.filled(cnt, Contrib()));
    }

    return contribList;
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
      color: Color(int.parse(json['color'].replaceAll(RegExp(r'#'), '0xFF'))),
    );
  }
}
