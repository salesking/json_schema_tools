require 'spec_helper'

class Client
  attr_accessor :first_name, :last_name, :addresses, :id
end

describe SchemaTools::Hash do

  context 'from_schema' do
    let(:client){Client.new}
    before :each do
      client.first_name = 'Peter'
      client.last_name = 'Paul'
    end
    after :each do
      SchemaTools::Reader.registry_reset
    end

    it 'should return hash' do
      hash = SchemaTools::Hash.from_schema(client)
      hash['client']['last_name'].should == 'Paul'
    end
  end
end

