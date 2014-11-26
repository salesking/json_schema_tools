require 'spec_helper'

class TestContact
  include SchemaTools::Modules::Attributes
  has_schema_attrs :client
end

class Numbers
  include SchemaTools::Modules::Attributes
  has_schema_attrs :numbers, :schema => schema_as_ruby_object
end

describe SchemaTools::Modules::Attributes do

  context 'included' do
    subject { TestContact.new }

    it 'should add getter methods' do
      subject.should respond_to(:last_name)
    end

    it 'should add setter methods' do
      subject.should respond_to('first_name=')
    end

    it 'should not add setter for readonly properties' do
      subject.should_not respond_to('id=')
      subject.should_not respond_to('created_at=')
    end

    it 'should add schema_name to class' do
      subject.class.schema_name.should == :client
    end

    it 'should add schema to class' do
      subject.class.schema.should == SchemaTools::Reader.read(:client)
    end

    it 'should add schema to object' do
      subject.schema.should == SchemaTools::Reader.read(:client)
    end
  end

  context 'new from_json' do

    it 'should create new object' do
      str = load_fixture_data('contact_plain.json')
      hash = JSON.parse(str)
      obj = TestContact.from_json(str)
      expect(obj.id).to eq hash['id']
      expect(obj.organisation).to eq hash['organisation']
      expect(obj.first_name).to eq hash['first_name']
      expect(obj.last_name).to eq hash['last_name']
   end

  end


  context 'attributes from dynamic schema' do
    subject { Numbers.new }

    it 'should add getter methods' do
      subject.should respond_to(:numbers)
    end

    it 'should add setter methods' do
      subject.should respond_to('numbers=')
    end

    it 'should not add setter for readonly properties' do
      subject.should_not respond_to('id=')
    end
  end
end

