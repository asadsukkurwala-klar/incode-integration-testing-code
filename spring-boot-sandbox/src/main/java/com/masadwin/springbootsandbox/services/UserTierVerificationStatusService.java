package com.masadwin.springbootsandbox.services;

import com.masadwin.springbootsandbox.verification.constants.VerificationStatus;
import com.masadwin.springbootsandbox.verification.constants.VerificationType;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class UserTierVerificationStatusService {

  private Map<String, Map<VerificationType, VerificationStatus>> userTierVerificationStatuses = new HashMap<>();

  public UserTierVerificationStatusService() {
    // Just some test data
    Map<VerificationType, VerificationStatus> verificationStatuses = createTestData();
    userTierVerificationStatuses.put("mas", verificationStatuses);
  }

  public Map<VerificationType, VerificationStatus> getTierVerificationStatusesForUser(String userId) {
    // return if statuses found, otherwise create and return default data because meh
    Map<VerificationType, VerificationStatus> verificationStatuses = userTierVerificationStatuses.get(userId);
    if (null == verificationStatuses) {
      verificationStatuses = createTestData();
      userTierVerificationStatuses.put(userId, verificationStatuses);
    }
    return verificationStatuses;
  }

  public void updateVerificationStatusForUser(String userId, VerificationType verificationType, VerificationStatus verificationStatus) {
    userTierVerificationStatuses.get(userId).put(verificationType, verificationStatus);
  }

  private Map<VerificationType, VerificationStatus> createTestData() {
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

}
