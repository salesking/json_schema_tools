require 'spec_helper'

class ClientWithRemote
  #include SchemaTools::Modules::Attributes
  include SchemaTools::Modules::Resource
  has_schema_attrs :client
  has_schema_links
end

describe SchemaTools::Modules::Resource do

  context 'class methods' do

    it 'should add find method' do
      ClientWithRemote.should respond_to(:find)
    end

    it 'should add find_all method' do
      ClientWithRemote.should respond_to(:find_all)
    end

  end

  context 'instance methods' do

    subject{ ClientWithRemote.new }

    it 'should have save method' do
      subject.should respond_to(:save)
    end
    it 'should have destroy method' do
      subject.should respond_to(:destroy)
    end

    xit 'should have connection' do
    end

  end

end

