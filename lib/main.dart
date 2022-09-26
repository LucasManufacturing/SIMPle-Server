import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';

//toServer is a sendPort allowing for main&widgets to message the server.
//fromServer is a receivePort currently dies outofscope with initServer however allows main to receive messages from server
//fromMain is a receivePort allowing for server to receive messages.
//toMain is a sendPort allowing server to send to messages to main

void main() async {
  runApp(const MyApp());
  SendPort toServer = await initServer();
  print('sentMsg');
  toServer.send('Hi This is Main, sending a String');
}

//Isolate Comms come from https://medium.com/@lelandzach/dart-isolate-2-way-communication-89e75d973f34
//ReceivePorts can't be passed as arguments.
//Thus create a receiveport in main and pass sendport to isolate
//Then create a receiveport in isolate and send isolates send port through the send port back to main

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
  bool serverOn = false;

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
                if (serverOn == true) {}
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

  String string = await fromMain.first;
  print('[fromMain to Isolate] $string');
  //

  var server = await HttpServer.bind(InternetAddress.anyIPv6, 80);
  await server.forEach((HttpRequest request) {
    request.response.write('Server Says Hi');
    request.response.close();
  });
}

class ServerData {
  var sendPort;
  ServerData({this.sendPort});
}
