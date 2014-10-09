require 'spec_helper'

describe SchemaTools::Schema do

  context '.initialize' do
    after :each do
      SchemaTools::Reader.registry_reset
    end

    it 'reads all schemas' do
      schema = SchemaTools::Schema.new("#{SchemaTools.schema_path}/client.json")
      expect(schema['name']).to eq 'client'
    end

  end

  context '.to_h' do
    after :each do
      SchemaTools::Reader.registry_reset
    end

    it 'returns hash with de-referenced $refs' do
      schema = SchemaTools::Schema.new("#{SchemaTools.schema_path}/one_of_definition.json")
      hash = schema.to_h
      first = hash['properties']['person']['oneOf'][0]
      expect(first['title']).to eq 'client'
    end

  end

end

