package com.masadwin.springbootsandbox.controllers;

import static com.masadwin.springbootsandbox.models.IncodeOnboardingConfig.IncodeStartSingleVerificationConfig.fromStartOnboardingResponse;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.masadwin.springbootsandbox.models.IncodeOnboardingConfig;
import com.masadwin.springbootsandbox.models.IncodeWebhookRequestModel;
import com.masadwin.springbootsandbox.verification.constants.VerificationStatus;
import com.masadwin.springbootsandbox.verification.constants.VerificationType;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
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

  private RestTemplate restTemplate = new RestTemplate();
  private ObjectMapper objectMapper = new ObjectMapper();

  @GetMapping("incode/config")
  public IncodeOnboardingConfig getIncodeConfig(
      @RequestParam("userId") String userId,
      @RequestParam("verificationTypes")  List<VerificationType> verificationTypes) {

    Map<VerificationType, IncodeOnboardingConfig.IncodeStartSingleVerificationConfig> sessions = new HashMap<>();
    verificationTypes.stream().forEach(verificationType -> {
      String externalId = verificationType.name() + EXTERNAL_ID_SEPARATOR + userId;
      Map startOnboardingResponse = startOnboarding(externalId);
      sessions.put(verificationType, fromStartOnboardingResponse(startOnboardingResponse, externalId));
    });

    return IncodeOnboardingConfig.builder()
        .apiKey(incodeApiKey)
        .incodeApiUrl(incodeApiUrl)
        .incodeStartSingleVerificationConfigMap(sessions)
        .build();
  }

  @GetMapping("verification/status")
  public Map<VerificationType, VerificationStatus> getVerificationStatus(@RequestParam("userId") String userId) {
    Map<VerificationType, VerificationStatus> verificationStatuses = new HashMap<>();
    // creating a map with all verifications COMPLETE so that we don't redo all of them
    Arrays.stream(VerificationType.values()).forEach(verificationType -> {
      verificationStatuses.put(verificationType, VerificationStatus.COMPLETE);
    });
    // now set specific verifications as NEEDED for testing purposes
    verificationStatuses.put(VerificationType.PHOTO_ID, VerificationStatus.NEEDED);
    verificationStatuses.put(VerificationType.LIVENESS, VerificationStatus.NEEDED);
    return verificationStatuses;
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
    markVerificationAsComplete(incodeWebhookRequestModel.getVerificationType(), userId);
  }

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

  private Map startOnboarding(String externalId) {
    String countryCode = "ALL";
    Map<String, String> body = Map.of(
        "configurationId", incodeConfigFlowId, // useless but ok
        "externalId", externalId,
        "countryCode", countryCode
    );
    HttpEntity<?> httpEntity = new HttpEntity<>(body, createHttpHeaders());
    Map response = restTemplate.exchange(incodeApiUrl + "/omni/start", HttpMethod.POST, httpEntity, Map.class).getBody();
    log.info("startOnboarding: received response {}", response);
    return response;
  }

  private HttpHeaders createHttpHeaders(String token) {
    HttpHeaders headers = new HttpHeaders();
    headers.add("x-api-key", incodeApiKey);
    headers.add("api-version", incodeApiVersion);
    if (null != token) {
      headers.add("x-incode-hardware-id", token);
    }
    return headers;
  }

  private HttpHeaders createHttpHeaders() {
    return createHttpHeaders(null);
  }

  public static final String EXTERNAL_ID_SEPARATOR = ":";
}
