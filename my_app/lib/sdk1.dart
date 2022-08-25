import 'package:flutter/material.dart';
import 'package:my_app/shared.variables.dart';
import 'package:my_app/uiHelper.dart';
import 'package:onboarding_flutter_wrapper/onboarding_flutter_wrapper.dart';
import 'backend.operations.dart';

/// Implementation using startOnboarding, which requires us to provide apiKey in the sdk. Not ideal, but works OK.
/// This relies on having a separate session for each sdk module.
/// Problem with this implementation is that the backend has to keep track of all verifications and only pass/fail
/// after the final verification is complete
class SdkV1Implementation {

  BackendOperations backendOperations = BackendOperations();
  UIHelper uiHelper = UIHelper();
  SharedVariables sharedVariables = SharedVariables();

  void initSdk(BuildContext context) async {
    Map<String, dynamic> verificationStatuses = await backendOperations.getVerifications(sharedVariables.getVerificationStatusesUrl, sharedVariables.userId);
    // filter out verifications that have been completed
    Map<String, dynamic> verificationStatusesToBeDone =
    Map.from(verificationStatuses)..removeWhere((key, value) => !SharedVariables.doVerificationStatuses.contains(value.toString()));
    String verificationTypesQueryString = 'verificationTypes=${verificationStatusesToBeDone.keys.join("&verificationTypes=")}';
    Map<String, dynamic> incodeConfigMap =
    await backendOperations.getIncodeConfig('${sharedVariables.getIncodeConfigUrl}?userId=${sharedVariables.userId}&$verificationTypesQueryString');
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
        _startOnboardingV1(context, sessions);
      },
      onError: (String error) {
        print('Incode SDK init failed: $error');
        uiHelper.showAlertDialog(context, 'Incode SDK init failed: $error');
      },
    );
  }

  /// SDK 1.2.0
  void _startOnboardingV1(BuildContext context, Map<String, dynamic> sessions) {
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
    String verificationType = externalId.substring(0, externalId.indexOf(SharedVariables.separator));
    OnboardingFlowConfiguration flowConfiguration = _createOnboardingFlowConfiguration(verificationType);

    IncodeOnboardingSdk.startOnboarding(
        sessionConfig: sessionConfiguration,
        flowConfig: flowConfiguration,
        onSuccess: () => {
          // simulating a webhook callback
          backendOperations.postWebhook(sharedVariables.backendBaseUrl, interviewId, externalId),
          // start a new verification until all verifications are done
          if (sessions.isEmpty)
            {uiHelper.showAlertDialog(context, "Onboarding Completed Successfully")}
          else
            {_startOnboardingV1(context, sessions)}
        },
        onError: (error) => {uiHelper.showAlertDialog(context, 'Onboarding Error: $error')}
    );
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
}