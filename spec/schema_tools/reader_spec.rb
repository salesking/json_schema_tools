require 'spec_helper'

describe SchemaTools::Reader do

  context 'class methods' do

    after :each do
      SchemaTools::Reader.registry_reset
    end

    it 'should read a single schema' do
      schema = SchemaTools::Reader.read(:page)
      schema[:name].should == 'page'
      schema[:properties].should_not be_empty
      SchemaTools::Reader.registry.should_not be_empty
    end

    it 'should read a schema with inheritance' do
      schema = SchemaTools::Reader.read(:lead) # extends contact

      SchemaTools::Reader.registry[:contact].should_not be_empty
      SchemaTools::Reader.registry[:lead].should_not be_empty

      schema[:properties][:first_name].should_not be_empty
      schema[:properties][:lead_source].should_not be_empty
    end

    it 'should read a schema from a Ruby Hash' do
      schema = SchemaTools::Reader.read(:numbers, schema_as_ruby_object)

      SchemaTools::Reader.registry[:numbers].should_not be_empty

      schema[:properties][:numbers].should_not be_empty
    end

    it 'should deal with referenced parameters properly' do
      schema = SchemaTools::Reader.read(:includes_basic_definitions)
      schema[:properties].should_not be_empty
      schema[:properties].length.should eq 3
      schema[:properties][:id][:description].should eq "some description"

      schema[:properties][:id]["$ref"].should be_nil
    end

    it 'should enforce correct parameter usage' do
      expect { SchemaTools::Reader.read(:contact, []) }.to raise_error ArgumentError
    end
  end

  context 'instance methods' do

    let(:reader){ SchemaTools::Reader.new }

    it 'should read a single schema' do
      schema = reader.read(:client)
      schema[:name].should == 'client'
      schema[:properties].should_not be_empty
      reader.registry[:client].should_not be_empty
    end

    it 'should read a single schema from Ruby Hash' do
      schema = reader.read(:numbers, schema_as_ruby_object)
      schema[:name].should == 'numbers'
      schema[:properties].should_not be_empty
    end

    it 'should populate instance registry' do
      reader.read(:client)
      reader.read(:address)
      keys = reader.registry.keys
      keys.length.should == 2
      keys.should include(:client, :address)
    end

    it 'should not populate class registry' do
      reader.read(:client)
      SchemaTools::Reader.registry.should be_empty
    end

    it 'should enforce correct parameter usage' do
      expect { reader.read(:client, []) }.to raise_error ArgumentError
    end
  end
end

