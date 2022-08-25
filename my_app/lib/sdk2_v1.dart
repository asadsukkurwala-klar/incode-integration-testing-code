import 'package:flutter/material.dart';
import 'package:onboarding_flutter_wrapper/onboarding_flutter_wrapper.dart';

import 'backend.operations.dart';
import 'shared.variables.dart';
import 'uiHelper.dart';

/// Uses setupOnboardingSession which ensures we don't have to provide apiKey in the sdk, but the implementation
/// has a bug where it does not pick minor config (timeouts and retries)
/// Like V1 implementation, this also relies on having a separate session for each sdk module. This requires us to
/// finish the flow after every verification so that backend can handle the webhook.
class SdkV2ImplementationFirstMethod {

  BackendOperations backendOperations = BackendOperations();
  UIHelper uiHelper = UIHelper();
  SharedVariables sharedVariables = SharedVariables();

  void _initSdkV2(BuildContext context) async {
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
    String incodeApiUrl = incodeConfigMap["incodeApiUrl"];
    Map<String, dynamic> sessions = incodeConfigMap["incodeStartSingleVerificationConfigMap"];

    IncodeOnboardingSdk.init(
      apiUrl: '$incodeApiUrl/0/',
      testMode: false,
      loggingEnabled: true,
      onSuccess: () {
        print('Incode initialize successfully!');
        _startOnboardingV2(context, sessions);
      },
      onError: (String error) {
        print('Incode SDK init failed: $error');
        uiHelper.showAlertDialog(context, '_initSdkV2 Error: $error');
      },
    );
  }

  /// SDK 2.0.0
  void _startOnboardingV2(BuildContext context, Map<String, dynamic> sessions) {
    dynamic incodeStartSingleVerificationConfig = sessions.remove(sessions.keys.first);
    String interviewId = incodeStartSingleVerificationConfig["interviewId"];
    String token = incodeStartSingleVerificationConfig["token"];
    String externalId = incodeStartSingleVerificationConfig["externalId"];

    String verificationType = externalId.substring(0, externalId.indexOf(SharedVariables.separator));
    // hardcoding flow/configurationId for now. ConfigurationId controls the finer details of the modules such as timeouts, retries
    String configurationId = "629540c0362696001836915b";
    OnboardingSessionConfiguration sessionConfiguration = OnboardingSessionConfiguration(token: token, interviewId: interviewId, externalId: externalId, configurationId: configurationId);
    IncodeOnboardingSdk.setupOnboardingSession(sessionConfig: sessionConfiguration,
        onSuccess: (result) => {
          _onSetupOnboardingSessionSuccess(context, result, verificationType, () => {_onSingleSdkModuleFinished(context, sessions, interviewId, externalId)})
        },
        onError: (error) => {uiHelper.showAlertDialog(context, 'Onboarding Error: $error')});
  }

  void _onSingleSdkModuleFinished(BuildContext context, Map<String, dynamic> sessions, String interviewId, String externalId) {
    IncodeOnboardingSdk.finishFlow(onError: (err) => {
      uiHelper.showAlertDialog(context, 'finishFlow Error: $err')
    }, onSuccess: () => {
      print('finishFlow success'),
      // simulating a webhook callback
      backendOperations.postWebhook(sharedVariables.backendBaseUrl, interviewId, externalId),
      // start a new verification until all verifications are done
      if (sessions.isEmpty)
        {uiHelper.showAlertDialog(context, "Onboarding Completed Successfully")}
      else
        {_startOnboardingV2(context, sessions)}
    });
  }

  void _onSetupOnboardingSessionSuccess(BuildContext context, OnboardingSessionResult onboardingSessionResult,
      String verificationType,
      Function() onVerificationCompleted) {
    if (verificationType == "PHOTO_ID") {
      OnboardingFlowConfiguration flowConfiguration = OnboardingFlowConfiguration();
      flowConfiguration.addIdScan();
      flowConfiguration.addProcessId();
      IncodeOnboardingSdk.startNewOnboardingSection(flowConfig: flowConfiguration,
          onError: (error) => {uiHelper.showAlertDialog(context, '_onSetupOnboardingSessionError: $error')},
          onIdProcessed: (result) => {onVerificationCompleted()}
      );
    }
    if (verificationType == "LIVENESS") {
      OnboardingFlowConfiguration flowConfiguration = OnboardingFlowConfiguration();
      flowConfiguration.addSelfieScan();
      IncodeOnboardingSdk.startNewOnboardingSection(flowConfig: flowConfiguration,
          onError: (error) => {uiHelper.showAlertDialog(context, '_onSetupOnboardingSessionError: $error')},
          onSelfieScanCompleted: (result) => {onVerificationCompleted()}
      );
    }
  }
}