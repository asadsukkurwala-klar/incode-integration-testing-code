package com.masadwin.springbootsandbox.utils;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;

@Component
public class SpringHttpHelper {

  @Value("${kyc.incode.api.key}")
  private String incodeApiKey;
  @Value("${kyc.incode.api.version}")
  private String incodeApiVersion;

  public HttpHeaders createHttpHeaders(String token) {
    HttpHeaders headers = new HttpHeaders();
    headers.add("x-api-key", incodeApiKey);
    headers.add("api-version", incodeApiVersion);
    if (null != token) {
      headers.add("x-incode-hardware-id", token);
    }
    return headers;
  }

  public HttpHeaders createHttpHeaders() {
    return createHttpHeaders(null);
  }
}
