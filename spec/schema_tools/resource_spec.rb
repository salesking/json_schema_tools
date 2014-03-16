require 'spec_helper'

class ClientWithRemote
  include SchemaTools::Modules::Attributes
  include SchemaTools::Modules::Resource
  has_schema_attrs :client
  has_schema_links
end

describe SchemaTools::Modules::Resource do

  context 'class methods' do

    let(:klass){ ClientWithRemote.new }
    it 'should add destroy method' do
      klass.respond_to?(:destroy).should be
    end

  end

  context 'instance methods' do

    #let(:reader){ SchemaTools::Resource.new }

    xit 'should have connection' do
    end

  end
end

