class SharedVariables {

  String backendBaseUrl = 'http://192.168.1.216:8081/kyc';
  late String getIncodeConfigUrl = '$backendBaseUrl/incode/config';
  late String getVerificationStatusesUrl = '$backendBaseUrl/verification/status';
  late String postWebhookUrl = '$backendBaseUrl/incode/webhook';
  late String userId = "mas";
  static const String separator = ":";
  static const doVerificationStatuses = ["NEEDED", "TO_BE_RETRIED"];
}