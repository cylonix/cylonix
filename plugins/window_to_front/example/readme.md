## Scenario

When you want user to authenticate the user from browser, Your app will be pushed behind the web browser you are using to authenticate, and once the authentication flow in the browser, you would want your application to come to the front again.

## How to use


```dart

import 'package:flutter/material.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:window_to_front/window_to_front.dart'; // Add this,
import 'github_oauth_credentials.dart';
import 'src/github_gql/github_queries.data.gql.dart';
import 'src/github_gql/github_queries.req.gql.dart';
import 'src/github_login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub GraphQL API Client',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'GitHub GraphQL API Client'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return GithubLoginWidget(
      builder: (context, httpClient) {
        WindowToFront.activate();                      // and this.
        final link = HttpLink(
          'https://api.github.com/graphql',
          httpClient: httpClient,
        );
        return FutureBuilder<GViewerDetailData_viewer>(
          future: viewerDetail(link),
          builder: (context, snapshot) {
            return Scaffold(
              appBar: AppBar(
                title: Text(title),
              ),
              body: Center(
                child: Text(
                  snapshot.hasData
                      ? 'Hello ${snapshot.data!.login}!'
                      : 'Retrieving viewer login details...',
                ),
              ),
            );
          },
        );
      },
      githubClientId: githubClientId,
      githubClientSecret: githubClientSecret,
      githubScopes: githubScopes,
    );
  }
}

Future<GViewerDetailData_viewer> viewerDetail(Link link) async {
  final req = GViewerDetail((b) => b);
  final result = await link
      .request(Request(
        operation: req.operation,
        variables: req.vars.toJson(),
      ))
      .first;
  final errors = result.errors;
  if (errors != null && errors.isNotEmpty) {
    throw QueryException(errors);
  }
  return GViewerDetailData.fromJson(result.data!)!.viewer;
}

class QueryException implements Exception {
  QueryException(this.errors);
  List<GraphQLError> errors;
  @override
  String toString() {
    return 'Query Exception: ${errors.map((err) => '$err').join(',')}';
  }
}

```