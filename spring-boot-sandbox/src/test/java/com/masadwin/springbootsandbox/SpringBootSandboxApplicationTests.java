package com.masadwin.springbootsandbox;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.gson.Gson;
import com.masadwin.springbootsandbox.models.TestJsonSerializable;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class SpringBootSandboxApplicationTests {

	@Test
	void contextLoads() throws JsonProcessingException {
		String json = "{\"numbers\": [1,2,3]}";
		TestJsonSerializable tjsJackson = new ObjectMapper().readValue(json, TestJsonSerializable.class);
		TestJsonSerializable tjsGson = new Gson().fromJson(json, TestJsonSerializable.class);
		System.out.println("end");
	}

}
