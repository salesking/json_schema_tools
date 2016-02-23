require 'spec_helper'

# Tests related to module inclusion in custom classes
describe 'SchemaTools::Modules' do

  context 'conflicting method names' do

    class BarTest
      include SchemaTools::Modules::Attributes
      include SchemaTools::Modules::AsSchema
      has_schema_attrs :bar, schema: {
                                      "type" => "object",
                                      "name" => "bar",
                                      "properties" => {
                                        "foo" => {
                                          "type"  => "string"
                                        },
                                        "foo_1" => {
                                          "type"  => "string"
                                        }
                                      }
                                     }

      # method already defined, but also 'added' by schema attributes
      def foo
        'do something'
      end
      def foo_1
        # do whatever in this case returns nil
      end
    end


    it 'does not override existing method' do
      res = BarTest.from_hash({ 'foo' => 'test value', 'foo_1'=>'another test' })

      # foo just returns its instance method value
      expect(res.foo).to eq 'do something'
      expect(res.as_schema_hash['foo']).to eq 'do something'

      expect(res.foo_1).to eq nil
      expect(res.as_schema_hash['foo_1']).to eq nil

      # the schema_attr still have the given values
      expect(res.schema_attrs['foo']).to eq 'test value'
      expect(res.schema_attrs['foo_1']).to eq 'another test'
    end

  end
end

