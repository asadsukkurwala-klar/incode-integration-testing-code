package com.masadwin.springbootsandbox.models;

import com.masadwin.springbootsandbox.verification.constants.VerificationStatus;
import com.masadwin.springbootsandbox.verification.constants.VerificationType;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UpdateUserTierVerificationStatusRequestModel {

  private String userId;
  private VerificationType verificationType;
  private VerificationStatus verificationStatus;
}
