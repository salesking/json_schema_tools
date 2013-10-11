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

