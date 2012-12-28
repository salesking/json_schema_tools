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
  end

  context 'instance methods' do

    let(:reader){ SchemaTools::Reader.new }

    it 'should read a single schema' do
      schema = reader.read(:client)
      schema[:name].should == 'client'
      schema[:properties].should_not be_empty
      reader.registry[:client].should_not be_empty
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

  end

end

