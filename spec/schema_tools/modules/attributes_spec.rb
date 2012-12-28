require 'spec_helper'

class Contact
  include SchemaTools::Modules::Attributes
  has_schema_attrs :client
end

describe SchemaTools::Modules::Attributes do

  context 'included' do
    let(:contact){Contact.new}

    it 'should add getter methods' do
      contact.respond_to?(:last_name).should be_true
    end

    it 'should add setter methods' do
      contact.respond_to?('first_name=').should be_true
    end

    it 'should not add setter for readonly properties' do
      contact.respond_to?('id=').should be_false
    end
  end
end

