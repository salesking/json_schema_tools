require 'spec_helper'

class ContactWithLinks
  #include SchemaTools::Modules::Attributes
  include SchemaTools::Modules::Resource
  has_schema_attrs :client
  has_schema_links #before_request: set_auth
end

describe SchemaTools::Modules::Attributes do

  context 'included' do
    subject { ContactWithLinks.new }

    it 'should add link methods' do
      ContactWithLinks.should respond_to(:find)
    end

    it 'should add destroy method' do
      subject.should respond_to('destroy')
    end

  end

end

