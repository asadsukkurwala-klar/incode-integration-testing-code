package com.masadwin.springbootsandbox.controllers;

import org.springframework.http.HttpEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping("index")
public class IndexController {

	@GetMapping("")
	public ResponseEntity<?> defaultPathGet(@RequestParam(value = "error", required = false) String error, HttpEntity<String> httpEntity) throws Exception {
		System.out.println("headers: " + httpEntity.getHeaders());
		if (null != error) {
			throw new Exception(error);
		}
		return ResponseEntity.ok("{}");
		//return new ResponseEntity<>("{\"timestamp\":\"2022-07-15T10:49:17.324+00:00\",\"status\":444,\"error\":\"Internal Server Error\",\"path\":\"/index\"", HttpStatus.OK);
	}

	@PostMapping("")
	public ResponseEntity<?> defaultPathPost(@RequestParam(value = "error", required = false) String error, HttpEntity<String> httpEntity) throws Exception {
		System.out.println("headers: " + httpEntity.getHeaders());
		if (null != error) {
			throw new Exception(error);
		}
		return ResponseEntity.ok("{\"test\": \"value\"}");
		//return new ResponseEntity<>("{\"timestamp\":\"2022-07-15T10:49:17.324+00:00\",\"status\":444,\"error\":\"Internal Server Error\",\"path\":\"/index\"", HttpStatus.OK);
	}

}
