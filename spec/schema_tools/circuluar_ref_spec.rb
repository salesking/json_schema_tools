require 'spec_helper'

describe SchemaTools::Reader do
  BROKEN_SCHEMA_PATH = File.join(fixture_path, 'schemata_broken')
  context 'circular references' do
    it 'should raise exception for circular $refs' do
      expect{
        schema = SchemaTools::Schema.new("#{BROKEN_SCHEMA_PATH}/circular_references.json")
      }.to raise_exception(SchemaTools::CircularReferenceException)
    end
    it 'should raise exception for more complex circular $refs' do
      expect{
        schema = SchemaTools::Schema.new("#{BROKEN_SCHEMA_PATH}/circular_references_multi.json")
      }.to raise_exception(SchemaTools::CircularReferenceException)
    end
    it 'should raise exception for way multi file circular $refs' do
      expect {
        schema = SchemaTools::Schema.new("#{BROKEN_SCHEMA_PATH}/circular_references_multi_file_one.json")
      }.to raise_exception
    end
    it 'should not raise exception if same $ref is used twice in one file' do
      expect {
        SchemaTools::Reader.read(:circular_references_twice)
      }.to_not raise_exception
    end
  end
end

