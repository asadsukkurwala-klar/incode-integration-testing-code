package com.masadwin.springbootsandbox.models;

import static com.masadwin.springbootsandbox.controllers.KycController.EXTERNAL_ID_SEPARATOR;

import com.masadwin.springbootsandbox.verification.constants.VerificationType;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class IncodeWebhookRequestModel {

  private String interviewId;
  private String externalId;
  private OnboardingStatus onboardingStatus;

  public VerificationType getVerificationType() {
    String verificationTypeString = externalId.substring(0, externalId.indexOf(EXTERNAL_ID_SEPARATOR));
    return VerificationType.valueOf(verificationTypeString);
  }

  public String getUserId() {
    return externalId.substring(externalId.indexOf(EXTERNAL_ID_SEPARATOR) + 1);
  }

  public static enum OnboardingStatus {
    UNKNOWN, ID_VALIDATION_FINISHED, POST_PROCESSING_FINISHED, FACE_VALIDATION_FINISHED, ONBOARDING_FINISHED, MANUAL_REVIEW_APPROVED, MANUAL_REVIEW_REJECTED
  }

}
