import 'dart:async';

import 'package:flutter_darwin_notification/flutter_darwin_notification.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final subscriptions = <StreamSubscription>[];

  Result result;

  Result result2;
  @override
  void initState() {
    super.initState();
    final center = DarwinNotificationCenter();

    final stream1 = center.observe(name: 'testNotification');
    subscriptions.add(stream1.listen((result) {
      setState(() {
        this.result = result;
      });
    }));

    final stream2 = center.observe(
        name: 'testNotification2', behavior: Behavior.deliverImmediately);
    subscriptions.add(stream2.listen((result) {
      setState(() {
        result2 = result;
      });
    }));

    center.postNotification('testNotification',
        object: '1', deliverImmediately: false);

    center.postNotification('testNotification2', object: '1');
  }

  @override
  void dispose() {
    subscriptions.forEach((subscription) => subscription.cancel());
    subscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            Text('Received native notification: ${result?.toString()} \n'),
            Text('Received native notification2: ${result2?.toString()} \n'),
          ],
        ),
      ),
    );
  }
}
