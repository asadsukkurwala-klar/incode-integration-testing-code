package com.masadwin.springbootsandbox.controllers;

import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.web.bind.annotation.GetMapping;
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

  @GetMapping("incode/config")
  public Map<String, Object> getIncodeConfig(@RequestParam("externalId") String externalId) {
    Map startOnboardingResponse = startOnboarding(externalId);
    return Map.of(
        "apiKey", incodeApiKey,
        "token", startOnboardingResponse.get("token"),
        "interviewId", startOnboardingResponse.get("interviewId"),
        "flowConfigId", incodeConfigFlowId,
        "incodeApiUrl", incodeApiUrl
    );
  }

  private Map startOnboarding(String externalId) {
    String countryCode = "MEX";
    Map<String, String> body = Map.of(
        "configurationId", incodeConfigFlowId,
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
}
