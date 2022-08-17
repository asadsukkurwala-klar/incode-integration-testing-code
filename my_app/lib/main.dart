import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onboarding_flutter_wrapper/onboarding_flutter_wrapper.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String getIncodeConfigUrl = 'http://localhost:8081/kyc/incode/config?externalId=';
  String externalId = "";
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  Future<Map<String, dynamic>> getIncodeConfig(String url) async {
    return await http.get(Uri.parse(url))
        .then((response) => jsonDecode(response.body));
  }

  void _initSdk() async {
    Map<String, dynamic> incodeConfigMap = await getIncodeConfig(this.getIncodeConfigUrl + this.externalId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(incodeConfigMap.toString()),
    ));
    String apiKey = incodeConfigMap["apiKey"];
    String token = incodeConfigMap["token"];
    String interviewId = incodeConfigMap["interviewId"];
    String flowConfigId = incodeConfigMap["flowConfigId"];
    String incodeApiUrl = incodeConfigMap["incodeApiUrl"];
    IncodeOnboardingSdk.init(
      apiKey: apiKey,
      apiUrl: incodeApiUrl,
      testMode: false,
      loggingEnabled: true,
      onSuccess: () {
        // Update UI, safe to start Onboarding
        print('Incode initialize successfully!');
        _startOnboarding(token, interviewId, this.externalId, flowConfigId);
        /*
      setState(() {
        initSuccess = true;
      });
      */
      },
      onError: (String error) {
        print('Incode SDK init failed: $error');
        /*
          setState(() {
            initSuccess = false;
          });
          */
        showAlertDialog(context, '$error');
      },
    );
  }

  void _startOnboarding(String token, String interviewId, String externalId, String flowConfigId) {
    OnboardingSessionConfiguration sessionConfiguration = OnboardingSessionConfiguration(configurationId: flowConfigId, externalId: externalId);
    OnboardingFlowConfiguration flowConfiguration = OnboardingFlowConfiguration();
    flowConfiguration.addIdScan();
    IncodeOnboardingSdk.startOnboarding(
        sessionConfig: sessionConfiguration,
        flowConfig: flowConfiguration,
        onSuccess: () => { showAlertDialog(context, "Onboarding Completed Successfully") },
        onError: (error) => { showAlertDialog(context, 'Onboarding Error: $error') }
    );
  }

  @override
  void initState() {
    super.initState();
    //showAlertDialog(context, "test");
    try {
      //throw Exception("test");
    } on Exception catch(_) {
      showAlertDialog(context, "test");
      fetchAlbum().then((value) => null);
    }
  }

  Future<http.Response> fetchAlbum() {
    return http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));
  }

  showAlertDialog(BuildContext context, String message) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Info"),
      content: Text('$message'),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'get incode config url',
                  hintText: this.getIncodeConfigUrl),
              controller: TextEditingController()..text = this.getIncodeConfigUrl,
              onChanged: (val) => {this.getIncodeConfigUrl = val},
              //fetchAlbum().then((value) => null);
            ),
            TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'startOnboarding externalId',
                  hintText: 'flowId:userId ???'),
              onChanged: (val) => {this.externalId = val},
            ),
            /*
            const TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'getApiKey Api Url',
                  hintText: 'http://localhost:8081/app/getApiKey'),
            )
            */
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _initSdk(),
        tooltip: 'Init',
        child: const Icon(Icons.start),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
