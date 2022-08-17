package com.masadwin.springbootsandbox;

import java.util.Map;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.error.DefaultErrorAttributes;
import org.springframework.boot.web.servlet.error.ErrorAttributes;
import org.springframework.context.annotation.Bean;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.WebRequest;

@SpringBootApplication
public class SpringBootSandboxApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringBootSandboxApplication.class, args);
	}

	/*
	@Bean
	public ErrorAttributes errorAttributes() {
		return new DefaultErrorAttributes() {
			@Override
			public Map<String, Object> getErrorAttributes(WebRequest webRequest, boolean includeStackTrace) {

				Map<String, Object> errorAttributes = super.getErrorAttributes(webRequest, includeStackTrace);

				Throwable error = getError(webRequest);

				errorAttributes.put("customMessage", error.getMessage());

				return errorAttributes;
			}
		};
	}
	*/
}
