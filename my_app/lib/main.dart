import 'dart:collection';
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
  String backendBaseUrl = 'http://192.168.1.216:8081/kyc';
  late String getIncodeConfigUrl = '$backendBaseUrl/incode/config';
  late String getVerificationStatusesUrl = '$backendBaseUrl/verification/status';
  late String postWebhookUrl = '$backendBaseUrl/incode/webhook';
  String userId = "";
  String SEPARATOR = ":";
  var DO_VERIFICATION_STATUSES = ["NEEDED", "TO_BE_RETRIED"];

  Future<Map<String, dynamic>> getIncodeConfig(String url) async {
    return await http.get(Uri.parse(url))
        .then((response) => jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> getVerifications(String url, String userId) async {
    return await http.get(Uri.parse(url + '?userId=$userId'))
        .then((response) => jsonDecode(response.body));
  }

  void _postWebhook(String interviewId, String externalId) async {
    Map<String, dynamic> body = {
      "onboardingStatus": "ONBOARDING_FINISHED",
      "interviewId": interviewId,
      "externalId": externalId
    };
    await http.post(Uri.parse('$backendBaseUrl/incode/webhook'), body: jsonEncode(body))
        .then((response) => jsonDecode(response.body));
  }

  void _initSdk() async {
    Map<String, dynamic> verificationStatuses = await getVerifications(this.getVerificationStatusesUrl, this.userId);
    // filter out verifications that have been completed
    Map<String, dynamic> verificationStatusesToBeDone =
        Map.from(verificationStatuses)..removeWhere((key, value) => !DO_VERIFICATION_STATUSES.contains(value.toString()));
    String verificationTypesQueryString = _createVerificationTypesQueryString(verificationStatusesToBeDone);
    Map<String, dynamic> incodeConfigMap =
        await getIncodeConfig(this.getIncodeConfigUrl + "?"
            + 'userId=${this.userId}'
            + '&$verificationTypesQueryString');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(incodeConfigMap.toString()),
    ));
    String apiKey = incodeConfigMap["apiKey"];
    String incodeApiUrl = incodeConfigMap["incodeApiUrl"];
    Map<String, dynamic> sessions = incodeConfigMap["incodeStartSingleVerificationConfigMap"];

    IncodeOnboardingSdk.init(
      apiKey: apiKey,
      apiUrl: incodeApiUrl,
      testMode: false,
      loggingEnabled: true,
      onSuccess: () {
        print('Incode initialize successfully!');
        _startOnboardingV1(sessions);
      },
      onError: (String error) {
        print('Incode SDK init failed: $error');
        showAlertDialog(context, '$error');
      },
    );
  }

  String _createVerificationTypesQueryString(Map<String, dynamic> verificationStatuses) {
    String queryString = "";
    verificationStatuses.forEach((key, value) {queryString += '&verificationTypes=$key';});
    return queryString.substring(1);
  }

  void _startOnboardingV2(Map<String, dynamic> sessions) {
    dynamic incodeStartSingleVerificationConfig = sessions.remove(sessions.keys.first);
    String interviewId = incodeStartSingleVerificationConfig["interviewId"];
    String token = incodeStartSingleVerificationConfig["token"];
    String externalId = incodeStartSingleVerificationConfig["externalId"];

    // hardcoding flow/configurationId for now because it doesn't matter
    String configurationId = "629540c0362696001836915b";
    OnboardingSessionConfiguration sessionConfiguration =
        OnboardingSessionConfiguration(configurationId: configurationId, externalId: externalId, token: token);
    String verificationType = externalId.substring(0, externalId.indexOf(SEPARATOR));
    IncodeOnboardingSdk.setupOnboardingSession(sessionConfig: sessionConfiguration,
        onSuccess: (result) => {
          // simulating a webhook callback
          _postWebhook(interviewId, externalId),
          // start a new verification until all verifications are done
          if (sessions.isEmpty)
            {showAlertDialog(context, "Onboarding Completed Successfully")}
          else
            {_startOnboardingV2(sessions)}
        },
        onError: (error) => {showAlertDialog(context, 'Onboarding Error: $error')});
  }

  // was implemented in SDK v1
  void _startOnboardingV1(Map<String, dynamic> sessions) {
    dynamic incodeStartSingleVerificationConfig = sessions.remove(sessions.keys.first);
    String interviewId = incodeStartSingleVerificationConfig["interviewId"];
    String token = incodeStartSingleVerificationConfig["token"];
    String externalId = incodeStartSingleVerificationConfig["externalId"];

    // hardcoding flow/configurationId for now because it doesn't matter
    String configurationId = "629540c0362696001836915b";
    OnboardingSessionConfiguration sessionConfiguration =
        OnboardingSessionConfiguration(configurationId: configurationId, externalId: externalId);
    //  OnboardingSessionConfiguration(externalId: externalId);
    String verificationType = externalId.substring(0, externalId.indexOf(SEPARATOR));
    OnboardingFlowConfiguration flowConfiguration = _createOnboardingFlowConfiguration(verificationType);

    IncodeOnboardingSdk.startOnboarding(
        sessionConfig: sessionConfiguration,
        flowConfig: flowConfiguration,
        onSuccess: () => {
          // simulating a webhook callback
          _postWebhook(interviewId, externalId),
          // start a new verification until all verifications are done
              if (sessions.isEmpty)
                {showAlertDialog(context, "Onboarding Completed Successfully")}
              else
                {_startOnboardingV1(sessions)}
            },
        onError: (error) => {showAlertDialog(context, 'Onboarding Error: $error')}
    );
  }

  // add more if needed
  Map<String, void Function(OnboardingFlowConfiguration flowConfiguration)> verificationTypeFlowConfigurer = {
    "PHOTO_ID": (flowConfiguration) => {flowConfiguration.addIdScan()},
    "GOVT_VALIDATION": (flowConfiguration) => {flowConfiguration.addGovernmentValidation()},
    "LIVENESS": (flowConfiguration) => {flowConfiguration.addSelfieScan()}
  };

  OnboardingFlowConfiguration _createOnboardingFlowConfiguration(String verificationType) {
    OnboardingFlowConfiguration flowConfiguration = OnboardingFlowConfiguration();
    verificationTypeFlowConfigurer[verificationType]!.call(flowConfiguration);
    return flowConfiguration;
  }

  @override
  void initState() {
    super.initState();
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
                  labelText: 'userId',
                  hintText: 'userId'),
              onChanged: (val) => {this.userId = val},
            ),
            TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'get verification statuses url',
                  hintText: this.getVerificationStatusesUrl),
              controller: TextEditingController()..text = this.getVerificationStatusesUrl,
              onChanged: (val) => {this.getVerificationStatusesUrl = val},
              //fetchAlbum().then((value) => null);
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
