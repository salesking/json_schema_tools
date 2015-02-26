# Set global fixtures path
def fixture_path
  File.expand_path('../fixtures/', __FILE__)
end
# load a json data object file returns the json string
# @return[String] file contents
def load_fixture_data(name)
   File.open(File.join(fixture_path,'data', name ), 'r') { |f| f.read }
end

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
          "readOnly" => true
        },
        "additionalProperties" => false
      }
    },
    "additionalProperties" => false
  }
end
