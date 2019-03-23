import 'dart:async';

import 'package:flutter/material.dart';
import 'package:github/server.dart';

GitHub github = createGitHubClient();

Future<Repository> fetchRepo() async {
  return await github.repositories.getRepository(new RepositorySlug("octocat", "Hello-World"));
}

void main() => runApp(App(repo: fetchRepo()));

class App extends StatelessWidget {
  final Future<Repository> repo;

  App({Key key, this.repo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch Data Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Fetch Data Example'),
        ),
        body: Center(
          child: FutureBuilder<Repository>(
            future: repo,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data.description);
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }

              // By default, show a loading spinner
              return CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}