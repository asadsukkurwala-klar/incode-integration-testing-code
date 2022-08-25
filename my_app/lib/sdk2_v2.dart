import 'package:flutter/material.dart';
import 'package:onboarding_flutter_wrapper/onboarding_flutter_wrapper.dart';

import 'backend.operations.dart';
import 'shared.variables.dart';
import 'uiHelper.dart';

/// Uses setupOnboardingSession which ensures we don't have to provide apiKey in the sdk, but the implementation
/// has a bug where it does not pick minor config (timeouts and retries)
/// This adds all the modules in a single session and uses sdk callbacks to update the verification status on backend.
class SdkV2ImplementationSecondMethod  {

  BackendOperations backendOperations = BackendOperations();
  UIHelper uiHelper = UIHelper();
  SharedVariables sharedVariables = SharedVariables();

  void initSdkV2(BuildContext context) async {
    Map<String, dynamic> verificationStatuses = await backendOperations.getVerifications(sharedVariables.getVerificationStatusesUrl, sharedVariables.userId);
    // filter out verifications that have been completed
    Map<String, dynamic> verificationStatusesToBeDone =
        Map.from(verificationStatuses)..removeWhere((key, value) => !SharedVariables.doVerificationStatuses.contains(value.toString()));
    if (verificationStatusesToBeDone.isEmpty) {
      uiHelper.showAlertDialog(context, "All verifications done");
      return;
    }
    Map<String, dynamic> incodeConfigMap =
        await backendOperations.getIncodeConfig('${sharedVariables.getIncodeConfigUrl}?userId=${sharedVariables.userId}');
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
        _startOnboardingV2(context, sessions, verificationStatusesToBeDone.keys.toList());
      },
      onError: (String error) {
        print('Incode SDK init failed: $error');
        uiHelper.showAlertDialog(context, '_initSdkV2 Error: $error');
      },
    );
  }

  /// SDK 2.0.0
  void _startOnboardingV2(BuildContext context, Map<String, dynamic> session, List<String> verificationTypes) {
    dynamic incodeStartSingleVerificationConfig = session.remove(session.keys.first);
    String interviewId = incodeStartSingleVerificationConfig["interviewId"];
    String token = incodeStartSingleVerificationConfig["token"];
    String externalId = incodeStartSingleVerificationConfig["externalId"]; // or session.keys.first, but that has been removed now
    // hardcoding flow/configurationId for now. ConfigurationId controls the finer details of the modules such as timeouts, retries
    String configurationId = "629540c0362696001836915b";
    OnboardingSessionConfiguration sessionConfiguration = OnboardingSessionConfiguration(token: token, interviewId: interviewId, externalId: externalId, configurationId: configurationId);
    IncodeOnboardingSdk.setupOnboardingSession(sessionConfig: sessionConfiguration,
        onSuccess: (result) => {
          _onSetupOnboardingSessionSuccess(context, result, externalId, verificationTypes)
        },
        onError: (error) => {uiHelper.showAlertDialog(context, 'Onboarding Error: $error')});
  }

  void _onSetupOnboardingSessionSuccess(
      BuildContext context,
      OnboardingSessionResult onboardingSessionResult,
      String userId,
      List<String> verificationType) {
    String completeStatus = "PENDING_VERIFICATION"; // Don't know what this currently means, but for IncodeImpl I'm thinking it indicates user has done their part, now we wait.
    OnboardingFlowConfiguration flowConfiguration = OnboardingFlowConfiguration();
    if (verificationType.contains("PHOTO_ID")) {
      flowConfiguration.addIdScan();
      flowConfiguration.addProcessId();
    }
    if (verificationType.contains("LIVENESS")) {
      flowConfiguration.addSelfieScan();
    }
    IncodeOnboardingSdk.startNewOnboardingSection(flowConfig: flowConfiguration,
        onError: (error) => {uiHelper.showAlertDialog(context, '_onSetupOnboardingSessionError: $error')},
        onIdProcessed: (result) => {backendOperations.updateVerificationProgress(sharedVariables.backendBaseUrl, userId, "PHOTO_ID", completeStatus)},
        onSelfieScanCompleted: (result) => {backendOperations.updateVerificationProgress(sharedVariables.backendBaseUrl, userId, "LIVENESS", completeStatus)}
        // ADD THE REST HERE
    );
  }
}