package com.masadwin.springbootsandbox.controllers;

import static com.masadwin.springbootsandbox.models.IncodeOnboardingConfig.IncodeStartSingleVerificationConfig.fromStartOnboardingResponse;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.masadwin.springbootsandbox.models.IncodeOnboardingConfig;
import com.masadwin.springbootsandbox.models.IncodeWebhookRequestModel;
import com.masadwin.springbootsandbox.models.UpdateUserTierVerificationStatusRequestModel;
import com.masadwin.springbootsandbox.services.UserTierVerificationStatusService;
import com.masadwin.springbootsandbox.utils.SpringHttpHelper;
import com.masadwin.springbootsandbox.verification.constants.VerificationStatus;
import com.masadwin.springbootsandbox.verification.constants.VerificationType;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
@RequestMapping("kyc")
@Slf4j
public class KycController {

  @Value("${kyc.incode.api.key}")
  private String incodeApiKey;
  @Value("${kyc.incode.api.version}")
  private String incodeApiVersion;
  @Value("${kyc.incode.config.flow.id}")
  private String incodeConfigFlowId;
  @Value("${kyc.incode.config.api.url}")
  private String incodeApiUrl;

  @Autowired
  private UserTierVerificationStatusService userTierVerificationStatusService;
  @Autowired
  private SpringHttpHelper springHttpHelper;

  private final RestTemplate restTemplate = new RestTemplate();
  private final ObjectMapper objectMapper = new ObjectMapper();

  @GetMapping("incode/config")
  public IncodeOnboardingConfig getIncodeConfig(
      @RequestParam("userId") String userId,
      @RequestParam(value = "verificationTypes", required = false)  List<VerificationType> verificationTypes) {

    Map<String, IncodeOnboardingConfig.IncodeStartSingleVerificationConfig> sessions = new HashMap<>();
    if (null != verificationTypes) {
      // if verification types is provided, start as many sessions
      verificationTypes.forEach(verificationType -> {
        String externalId = verificationType.name() + EXTERNAL_ID_SEPARATOR + userId;
        Map startOnboardingResponse = startOnboarding(externalId);
        sessions.put(verificationType.name(), fromStartOnboardingResponse(startOnboardingResponse, externalId));
      });
    } else {
      // this was added to handle a new implementation where we just use a single session and update the progress on
      // the backend by calling APIs from the front end (as opposed to relying on webhooks)
      String externalId = userId;
      Map startOnboardingResponse = startOnboarding(externalId);
      sessions.put(externalId, fromStartOnboardingResponse(startOnboardingResponse, externalId));
    }

    return IncodeOnboardingConfig.builder()
        .apiKey(incodeApiKey)
        .incodeApiUrl(incodeApiUrl)
        .incodeStartSingleVerificationConfigMap(sessions)
        .build();
  }

  @GetMapping("verification/status")
  public Map<VerificationType, VerificationStatus> getVerificationStatus(@RequestParam("userId") String userId) {
    return userTierVerificationStatusService.getTierVerificationStatusesForUser(userId);
  }

  @PutMapping("verification/status")
  public void updateVerificationStatus(@RequestBody UpdateUserTierVerificationStatusRequestModel updateUserTierVerificationStatusRequestModel) {
    userTierVerificationStatusService.updateVerificationStatusForUser(
        updateUserTierVerificationStatusRequestModel.getUserId(),
        updateUserTierVerificationStatusRequestModel.getVerificationType(),
        updateUserTierVerificationStatusRequestModel.getVerificationStatus()
    );
  }

  @PostMapping("incode/webhook")
  public void handleIncodeWebhook(@RequestBody IncodeWebhookRequestModel incodeWebhookRequestModel)
      throws JsonProcessingException {
    String jsonString = objectMapper.writeValueAsString(incodeWebhookRequestModel);
    System.out.println(jsonString);
    log.info("received webhook: {}", jsonString);
    String interviewId = incodeWebhookRequestModel.getInterviewId();
    String userId = incodeWebhookRequestModel.getUserId();
    validateScores(interviewId);
    validateOcrData(interviewId, userId);
    fetchAndSaveDocs(interviewId, userId);
    userTierVerificationStatusService.updateVerificationStatusForUser(userId, incodeWebhookRequestModel.getVerificationType(), VerificationStatus.COMPLETE);
  }

  private Map startOnboarding(String externalId) {
    String countryCode = "ALL";
    Map<String, String> body = Map.of(
        "configurationId", incodeConfigFlowId,
        "externalId", externalId,
        "countryCode", countryCode
    );
    HttpEntity<?> httpEntity = new HttpEntity<>(body, springHttpHelper.createHttpHeaders());
    Map response = restTemplate.exchange(incodeApiUrl + "/omni/start", HttpMethod.POST, httpEntity, Map.class).getBody();
    log.info("startOnboarding: received response {}", response);
    return response;
  }

  ///// STUBS TO EXPLAIN THE FLOW //////
  private void validateScores(String interviewId) {
    // make a fetch scores api call
    boolean acceptable = true;
    if (!acceptable) {
      throw new RuntimeException();
    }
  }

  private void validateOcrData(String interviewId, String userId) {
    Object user = null; // fetch from Klar DB
    Object ocrData = null; // fetch from incode API
    boolean match = user == ocrData;
    if (!match) {
      throw new RuntimeException();
    }
  }

  private void fetchAndSaveDocs(String interviewId, String userId) {
    // handle
  }

  private void markVerificationAsComplete(VerificationType verificationType, String userId) {
    // handle
  }

  public static final String EXTERNAL_ID_SEPARATOR = ":";
}
