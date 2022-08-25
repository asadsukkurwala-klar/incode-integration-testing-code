import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:my_app/shared.variables.dart';

class BackendOperations {

  SharedVariables sharedVariables = SharedVariables();

  Future<Map<String, dynamic>> getIncodeConfig(String url) async {
    return await http.get(Uri.parse(url))
        .then((response) => jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> getVerifications(String url, String userId) async {
    return await http.get(Uri.parse('$url?userId=$userId'))
        .then((response) => jsonDecode(response.body));
  }

  void postWebhook(String backendBaseUrl, String interviewId, String externalId) async {
    Map<String, dynamic> body = {
      "onboardingStatus": "ONBOARDING_FINISHED",
      "interviewId": interviewId,
      "externalId": externalId
    };
    Map<String, String> headers = {
      'content-type': 'application/json'
    };
    await http.post(Uri.parse('$backendBaseUrl/incode/webhook'), body: jsonEncode(body), headers: headers)
        .then((response) => print('received status code: ${response.statusCode} from webhook'));
  }

  void updateVerificationProgress(String backendBaseUrl, String userId, String verificationType, String verificationStatus) async {
    Map<String, dynamic> body = {
      "userId": userId,
      "verificationType": verificationType,
      "verificationStatus": verificationStatus
    };
    Map<String, String> headers = {
      'content-type': 'application/json'
    };
    await http.put(Uri.parse('$backendBaseUrl/verification/status'), body: jsonEncode(body), headers: headers)
        .then((response) => print('received status code: ${response.statusCode} from webhook'));
  }
}