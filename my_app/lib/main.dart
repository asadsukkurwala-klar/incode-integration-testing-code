import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onboarding_flutter_wrapper/onboarding_flutter_wrapper.dart';
import 'package:http/http.dart' as http;

// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: unused_element

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
  late String userId = "mas";
  static const String separator = ":";
  static const doVerificationStatuses = ["NEEDED", "TO_BE_RETRIED"];

  Future<Map<String, dynamic>> getIncodeConfig(String url) async {
    return await http.get(Uri.parse(url))
        .then((response) => jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> getVerifications(String url, String userId) async {
    return await http.get(Uri.parse('$url?userId=$userId'))
        .then((response) => jsonDecode(response.body));
  }

  void _postWebhook(String interviewId, String externalId) async {
    Map<String, dynamic> body = {
      "onboardingStatus": "ONBOARDING_FINISHED",
      "interviewId": interviewId,
      "externalId": externalId
    };
    Map<String, String> headers = {
      'content-type': 'application/json'
    };
    await http.post(Uri.parse('$backendBaseUrl/incode/webhook'), body: jsonEncode(body), headers: headers)
        .then((response) => jsonDecode(response.body));
  }

  void _initSdk() async {
    Map<String, dynamic> verificationStatuses = await getVerifications(getVerificationStatusesUrl, userId);
    // filter out verifications that have been completed
    Map<String, dynamic> verificationStatusesToBeDone =
        Map.from(verificationStatuses)..removeWhere((key, value) => !doVerificationStatuses.contains(value.toString()));
    String verificationTypesQueryString = 'verificationTypes=${verificationStatusesToBeDone.keys.join("&verificationTypes=")}';
    Map<String, dynamic> incodeConfigMap =
        await getIncodeConfig('$getIncodeConfigUrl?userId=$userId&$verificationTypesQueryString');
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
        showAlertDialog(context, 'Incode SDK init failed: $error');
      },
    );
  }

  /// SDK 1.2.0
  void _startOnboardingV1(Map<String, dynamic> sessions) {
    dynamic incodeStartSingleVerificationConfig = sessions.remove(sessions.keys.first);
    String interviewId = incodeStartSingleVerificationConfig["interviewId"];
    //String token = incodeStartSingleVerificationConfig["token"];
    String externalId = incodeStartSingleVerificationConfig["externalId"];

    // hardcoding flow/configurationId for now. ConfigurationId controls the finer details of the modules such as timeouts, retries
    String configurationId = "629540c0362696001836915b";
    // This code could be used with SDK 2.0.0, because it allows us to pick everything from the token itself.
    // Not much benefit though (that I can see)
    //OnboardingSessionConfiguration sessionConfiguration = OnboardingSessionConfiguration(token: token);
    OnboardingSessionConfiguration sessionConfiguration =
    OnboardingSessionConfiguration(configurationId: configurationId, externalId: externalId);
    String verificationType = externalId.substring(0, externalId.indexOf(separator));
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

  void _initSdkV2() async {
    Map<String, dynamic> verificationStatuses = await getVerifications(getVerificationStatusesUrl, userId);
    // filter out verifications that have been completed
    Map<String, dynamic> verificationStatusesToBeDone =
    Map.from(verificationStatuses)..removeWhere((key, value) => !doVerificationStatuses.contains(value.toString()));
    String verificationTypesQueryString = 'verificationTypes=${verificationStatusesToBeDone.keys.join("&verificationTypes=")}';
    Map<String, dynamic> incodeConfigMap =
    await getIncodeConfig('$getIncodeConfigUrl?userId=$userId&$verificationTypesQueryString');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(incodeConfigMap.toString()),
    ));
    String incodeApiUrl = incodeConfigMap["incodeApiUrl"];
    Map<String, dynamic> sessions = incodeConfigMap["incodeStartSingleVerificationConfigMap"];

    IncodeOnboardingSdk.init(
      apiUrl: '$incodeApiUrl/0/',
      testMode: false,
      loggingEnabled: true,
      onSuccess: () {
        print('Incode initialize successfully!');
        _startOnboardingV2(sessions);
      },
      onError: (String error) {
        print('Incode SDK init failed: $error');
        showAlertDialog(context, '_initSdkV2 Error: $error');
      },
    );
  }

  /// SDK 2.0.0
  void _startOnboardingV2(Map<String, dynamic> sessions) {
    dynamic incodeStartSingleVerificationConfig = sessions.remove(sessions.keys.first);
    String interviewId = incodeStartSingleVerificationConfig["interviewId"];
    String token = incodeStartSingleVerificationConfig["token"];
    String externalId = incodeStartSingleVerificationConfig["externalId"];

    // hardcoding flow/configurationId for now. ConfigurationId controls the finer details of the modules such as timeouts, retries
    String verificationType = externalId.substring(0, externalId.indexOf(separator));
    // hardcoding flow/configurationId for now. ConfigurationId controls the finer details of the modules such as timeouts, retries
    //String configurationId = "629540c0362696001836915b";
    OnboardingSessionConfiguration sessionConfiguration = OnboardingSessionConfiguration(token: token);
    IncodeOnboardingSdk.setupOnboardingSession(sessionConfig: sessionConfiguration,
        onSuccess: (result) => {
          _onSetupOnboardingSessionSuccess(result, verificationType, () => {_onSingleSdkModuleFinished(sessions, interviewId, externalId)})
        },
        onError: (error) => {showAlertDialog(context, 'Onboarding Error: $error')});
  }

  void _onSingleSdkModuleFinished(Map<String, dynamic> sessions, String interviewId, String externalId) {
    IncodeOnboardingSdk.finishFlow(onError: (err) => {
      showAlertDialog(context, 'finishFlow Error: $err')
    }, onSuccess: () => {
      print('finishFlow success'),
      // simulating a webhook callback
      _postWebhook(interviewId, externalId),
      // start a new verification until all verifications are done
      if (sessions.isEmpty)
        {showAlertDialog(context, "Onboarding Completed Successfully")}
      else
        {_startOnboardingV2(sessions)}
    });
  }

  void _onSetupOnboardingSessionSuccess(OnboardingSessionResult onboardingSessionResult,
      String verificationType,
      Function() onVerificationCompleted) {
    if (verificationType == "PHOTO_ID") {
      OnboardingFlowConfiguration flowConfiguration = OnboardingFlowConfiguration();
      flowConfiguration.addIdScan();
      flowConfiguration.addProcessId();
      IncodeOnboardingSdk.startNewOnboardingSection(flowConfig: flowConfiguration,
          onError: (error) => {showAlertDialog(context, '_onSetupOnboardingSessionError: $error')},
          onIdProcessed: (result) => {onVerificationCompleted()}
      );
    }
    if (verificationType == "LIVENESS") {
      OnboardingFlowConfiguration flowConfiguration = OnboardingFlowConfiguration();
      flowConfiguration.addSelfieScan();
      IncodeOnboardingSdk.startNewOnboardingSection(flowConfig: flowConfiguration,
          onError: (error) => {showAlertDialog(context, '_onSetupOnboardingSessionError: $error')},
          onSelfieScanCompleted: (result) => {onVerificationCompleted()}
      );
    }
  }

  OnboardingFlowConfiguration _createOnboardingFlowConfiguration(String verificationType) {
    // add more if needed
    Map<String, void Function(OnboardingFlowConfiguration flowConfiguration)> verificationTypeFlowConfigurer = {
      "PHOTO_ID": (flowConfiguration) => {flowConfiguration.addIdScan(),
        flowConfiguration.addProcessId()}, // this adds ocr
      "GOVT_VALIDATION": (flowConfiguration) => {flowConfiguration.addGovernmentValidation()},
      "LIVENESS": (flowConfiguration) => {flowConfiguration.addSelfieScan()}
    };
    OnboardingFlowConfiguration flowConfiguration = OnboardingFlowConfiguration();
    verificationTypeFlowConfigurer[verificationType]!.call(flowConfiguration);
    return flowConfiguration;
  }

  @override
  void initState() {
    super.initState();
  }

  showAlertDialog(BuildContext context, String message) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Info"),
      content: Text(message),
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
                  hintText: getIncodeConfigUrl),
              controller: TextEditingController()..text = getIncodeConfigUrl,
              onChanged: (val) => {getIncodeConfigUrl = val},
              //fetchAlbum().then((value) => null);
            ),
            TextField(
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'userId',
                  hintText: 'userId'),
              controller: TextEditingController()..text = userId,
              onChanged: (val) => {userId = val},
            ),
            TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'get verification statuses url',
                  hintText: getVerificationStatusesUrl),
              controller: TextEditingController()..text = getVerificationStatusesUrl,
              onChanged: (val) => {getVerificationStatusesUrl = val},
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
        onPressed: () => _initSdkV2(),
        tooltip: 'Init',
        child: const Icon(Icons.start),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
