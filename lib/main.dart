import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';

//toServer is a sendPort allowing for main&widgets to message the server.
//fromServer is a receivePort currently dies outofscope with initServer however allows main to receive messages from server
//fromMain is a receivePort allowing for server to receive messages.
//toMain is a sendPort allowing server to send to messages to main

void main() async {
  SendPort toServer = await initServer();
  runApp(MyApp(toServer: toServer));
  print('sentMsg');
  toServer.send('Hi This is Main, sending a String');
}

//==complicated fuckery regarding isolates and widgets kissing
//Isolate Comms come from https://medium.com/@lelandzach/dart-isolate-2-way-communication-89e75d973f34
//ReceivePorts can't be passed as arguments.
//Thus create a receiveport in main and pass sendport to isolate
//Then create a receiveport in isolate and send isolates send port through the send port back to main
//pass the above sendPort through the widgets as arguments. (Main to myApp, myApp through to homePage, homePage through to state. )

Future<SendPort> initServer() async {
  ReceivePort fromServer = ReceivePort();

  Completer<SendPort> toServer = Completer();
  //from reff var-type Completer needs to target the needed var, e.g Completer<SendPort>
  //fromMain requires a future as the isolate needs time to send it, however future types do not work as you cant just do "future<type> = type" so a completer acts as a middle man.
  Isolate myIsolateInstance =
      await Isolate.spawn(requestHandle, fromServer.sendPort);
  fromServer.listen((data) {
    if (data is SendPort) {
      print('Recieved Data $data');
      toServer.complete(data);
    }
  });
  print('returnedValue');
  return toServer.future;
}

class MyApp extends StatelessWidget {
  var toServer;
  MyApp({super.key, this.toServer});
  final int num1 = 123456789;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Server Application',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Main Screen', toServer: toServer),
    );
  }
}

class MyHomePage extends StatefulWidget {
  var toServer;
  MyHomePage({super.key, required this.title, this.toServer});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState(toServer: toServer);
}

class _MyHomePageState extends State<MyHomePage> {
  bool serverOn = false;
  var toServer;

  _MyHomePageState({this.toServer});
  void invertServerState() {
    setState(() {
      serverOn = !serverOn;
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
                if (serverOn == true) {
                  toServer.send('Open');
                } else {
                  toServer.send('Close');
                }
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

void requestHandle(SendPort toServer) async {
  ReceivePort fromMain = ReceivePort();
  toServer.send(fromMain.sendPort);
/* 
  String string = await fromMain.first;
  print('[fromMain to Isolate] $string');
  */

  var server = await HttpServer.bind(InternetAddress.anyIPv6, 80);
  server.close(); //intialize server then close
//works but when closed server.forEach function doesn't restart.
  fromMain.listen((data) async {
//    print('[fromNarnia to Server] ' + data);
    if (data == "Close") {
      server.close();
      print("Server Closes");
    }
    if (data == "Open") {
      //server only listening if data is open
      server = await HttpServer.bind(InternetAddress.anyIPv6, 80);

      print("Server Opens");
      await server.forEach((HttpRequest request) async {
        String content = await utf8.decoder
            .bind(request)
            .join(); //do all request work before responding otherwise it gets erased.
        print("Content: " + content);
        request.response.write('Server Says Hi');
        request.response
            .close(); //be sure to close otherwise client will wait for more.
      });
    }
  });
}
