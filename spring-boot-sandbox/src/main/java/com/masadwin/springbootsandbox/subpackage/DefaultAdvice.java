package com.masadwin.springbootsandbox.subpackage;

import java.util.HashMap;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

//@ControllerAdvice
public class DefaultAdvice {

  @ExceptionHandler(value = {RuntimeException.class})
  public ResponseEntity<?> handleRuntimeException(Exception ex) {
    Map<String, Object> responseObject = new HashMap<>();
    responseObject.put("message", "Runebear time " + ex.getMessage());
    return new ResponseEntity<>(responseObject, HttpStatus.INTERNAL_SERVER_ERROR);
  }

  @ExceptionHandler(value = {Exception.class})
  public ResponseEntity<?> handleDefaultException(Exception ex) {
    Map<String, Object> responseObject = new HashMap<>();
    responseObject.put("message", ex.getMessage());
    return new ResponseEntity<>(responseObject, HttpStatus.INTERNAL_SERVER_ERROR);
  }
}
