import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: ContribPage(),
    );
  }
}

class ContribPage extends StatefulWidget {
  @override
  ContribState createState() => new ContribState();
}

class ContribState extends State<ContribPage> {
  Future<List<Contrib>> contribs;

  @override
  void initState() {
    super.initState();
    contribs = _contribs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Everyday Contrib'),
      ),
      body: FutureBuilder<List<Contrib>>(
        future: contribs,
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);

          return snapshot.hasData
              ? GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                  ),
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    return Container(
                      color: snapshot.data[index].color,
                    );
                  },
                )
              : Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshContribs,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }

  Future<List<Contrib>> _contribs() async {
    final response =
        await http.get("https://github-contributions-api.now.sh/v1/178inaba");
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

  void _refreshContribs() async {
    setState(() {
      contribs = _contribs();
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
          Color(int.parse(json['color'].replaceAll(new RegExp(r'#'), '0xFF'))),
    );
  }
}
