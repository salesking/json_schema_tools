def schema_as_ruby_object
  {
    "type" => "object",
    "name" => "numbers",
    "properties" => {
      "numbers" => {
        "type"  => "array",
        "items" => {
          "type"    => "number",
          "minimum" => 1,
          "maximum" => 100
        },
        "id" => {
          "type"     => "number",
          "readonly" => true
        },
        "additionalProperties" => false
      }
    },
    "additionalProperties" => false
  }
end
