import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';

void main() async {
  runApp(const MyApp());
  requestHandle();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  final int num1 = 123456789;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Server Application',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Main Screen'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final int num2 = 123456789;
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool serverOn = true;
  void invertServerState() {
    setState(() {
      //     print(serverOn);
      serverOn = !serverOn;
      //    print(serverOn);
    });
  }

  String getServerStatusString() {
    if (serverOn) {
      return "online";
    } else {
      return "offline";
    }
  }

  Color getServerStatusColor() {
    if (serverOn) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.topCenter,
              color: getServerStatusColor(),
              padding: const EdgeInsets.all(10),
              child: Text('Server State: ' + getServerStatusString()),
            ),
            TextButton(
              onPressed: () {
                invertServerState();
              },
              child: Text("Change Server State"),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              ),
            )
          ],
        ),
      ),
    );
  }
}

Future<bool> requestHandle() async {
  print('executingLoop');
  var server = await HttpServer.bind(InternetAddress.anyIPv6, 80);
  print('executingLoop1');
  await server.forEach((HttpRequest request) {
    print(_MyHomePageState().serverOn);
    request.response.write('Server Says Hi');
    request.response.close();
  });
  return true;
}
