require 'spec_helper'

class ClassWithSchemaAttrs
  include SchemaTools::Modules::Attributes
  has_schema_attrs :client
end

class ClassWithSchemaName
  include SchemaTools::Modules::AsSchema
  schema_name :lead
end

# namespaced to not interfere with classes used in other tests
module Test
  class Address
    include SchemaTools::Modules::AsSchema
  end
end


describe SchemaTools::Modules::AsSchema do

  describe 'included' do
    subject { ClassWithSchemaAttrs.new }

    it 'should add as_schema_hash method' do
      subject.should respond_to(:as_schema_hash)
    end

    it 'should add as_schema_json method' do
      subject.should respond_to(:as_schema_json)
    end

    it 'should return hash' do
      subject.last_name = 'Hogan'
      hsh = subject.as_schema_hash
      hsh['client']['last_name'].should == 'Hogan'
    end

    it 'should return json' do
      subject.last_name = 'Hogan'
      json_str = subject.as_schema_json
      hsh = ActiveSupport::JSON.decode(json_str)
      hsh['client']['last_name'].should == 'Hogan'
    end

  end

  describe 'schema name detection' do

    it 'should use name from has_schema_attrs' do
      ClassWithSchemaAttrs.new.as_schema_hash.keys.should include('client', 'links')
    end

    it 'should use schema_name defined in class' do
      ClassWithSchemaName.new.as_schema_hash.keys.should include('lead')
    end

    it 'should use class name ' do
      Test::Address.new.as_schema_hash.keys.should include('address')
    end
  end

  describe 'schema options' do
    subject { ClassWithSchemaAttrs.new }

    it 'should override schema name from' do
      subject.as_schema_hash(class_name:'contact').keys.should include('contact')
    end

    it 'should use fields' do
      subject.as_schema_hash(fields:['id'])['client'].keys.should == ['id']
    end

    it 'should exclude root' do
      subject.as_schema_hash(exclude_root: true).keys.should include('id')
    end

    it 'should use class name ' do
      Test::Address.new.as_schema_hash.keys.should include('address')
    end
  end

end

