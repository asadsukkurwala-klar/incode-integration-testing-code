package com.masadwin.springbootsandbox.models;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.masadwin.springbootsandbox.verification.constants.VerificationType;
import java.util.Map;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@JsonInclude(JsonInclude.Include.NON_NULL)
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class IncodeOnboardingConfig {

  private String apiKey;
  private String incodeApiUrl;
  private Map<VerificationType, IncodeStartSingleVerificationConfig> incodeStartSingleVerificationConfigMap;

  @JsonInclude(JsonInclude.Include.NON_NULL)
  @Data
  @Builder
  @AllArgsConstructor
  @NoArgsConstructor
  public static class IncodeStartSingleVerificationConfig {
    private String token;
    private String interviewId;
    private String externalId;

    public static IncodeStartSingleVerificationConfig fromStartOnboardingResponse(Map responseJsonObject, String externalId) {
      return builder()
          .interviewId(responseJsonObject.get("interviewId").toString())
          .token(responseJsonObject.get("token").toString())
          .externalId(externalId)
          .build();
    }
  }
}
