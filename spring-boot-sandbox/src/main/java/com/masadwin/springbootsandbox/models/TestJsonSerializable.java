package com.masadwin.springbootsandbox.models;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.google.gson.annotations.SerializedName;
import java.util.List;
import lombok.Data;

@Data
public class TestJsonSerializable {

  @JsonProperty("numbers")
  @SerializedName("numbers")
  private List<Integer> numberList;
}
