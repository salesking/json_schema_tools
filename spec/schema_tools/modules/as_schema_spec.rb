require 'spec_helper'

class ClassWithSchemaAttrs
  include SchemaTools::Modules::Attributes
  has_schema_attrs :client
  # test override of schema name
  attr_accessor :contact_source
end

class ClassWithSchemaNameLead
  include SchemaTools::Modules::AsSchema
  schema_name :lead
end

# namespaced to not interfere with classes used in other tests
module Test
  class Address
    include SchemaTools::Modules::AsSchema
    attr_accessor :id, :city
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
      hsh['last_name'].should == 'Hogan'
    end

    it 'should return json' do
      subject.last_name = 'Hogan'
      json_str = subject.as_schema_json
      hsh = ActiveSupport::JSON.decode(json_str)
      hsh['last_name'].should == 'Hogan'
    end

  end

  describe 'schema name detection' do

    it 'should use name from has_schema_attrs' do
      ClassWithSchemaAttrs.new.as_schema_hash.keys.should include('phone_mobile', 'cash_discount')
    end

    it 'should use schema_name defined in class' do
      ClassWithSchemaNameLead.new.as_schema_hash.keys.should include('links_clicked')
    end

    it 'should infer schema from class name' do
      Test::Address.new.as_schema_hash.keys.should include('city')
    end
  end

  describe 'schema options' do
    subject { ClassWithSchemaAttrs.new }

    it 'should override schema name from' do
      subject.as_schema_hash(class_name:'contact').keys.should include('contact_source')
    end

    it 'should use fields' do
      subject.as_schema_hash(fields:['id']).keys.should == ['id']
    end
  end

end

