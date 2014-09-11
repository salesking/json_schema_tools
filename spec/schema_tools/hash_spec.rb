require 'spec_helper'

################################################################################
# classes used in tests their naming is important because the respecting
# json schema is derived from it
################################################################################
class Client
  attr_accessor :first_name, :id, :addresses, :work_address
end
class Address
  attr_accessor :city, :zip
end

class Contact
  attr_accessor :first_name, :last_name, :addresses, :id
  end

class OneOfDefinition
  attr_accessor :person
end

# see fixtures/lead.json
class Lead < Contact
  attr_accessor :links_clicked, :conversion
end

class Conversion
  attr_accessor :from, :to
end


describe SchemaTools::Hash do

  context 'from_schema to hash conversion' do

    let(:contact){Contact.new}
    before :each do
      contact.first_name = 'Peter'
      contact.last_name = 'Paul'
      contact.id = 'SomeID'
    end
    after :each do
      SchemaTools::Reader.registry_reset
    end

    it 'should return hash' do
      hash = SchemaTools::Hash.from_schema(contact)
      hash['contact']['last_name'].should == 'Paul'
    end

    it 'should use custom schema path' do
      custom_path = File.expand_path('../../fixtures', __FILE__)
      hash = SchemaTools::Hash.from_schema(contact, path: custom_path)
      hash['contact']['last_name'].should == 'Paul'
    end

    it 'should use custom schema' do
      hash = SchemaTools::Hash.from_schema(contact, class_name: :client)
      hash['client']['last_name'].should == 'Paul'
    end

    it 'should use only give fields' do
      hash = SchemaTools::Hash.from_schema(contact, fields: ['id', 'last_name'])
      hash['contact'].keys.length.should == 2
      hash['contact']['last_name'].should == contact.last_name
      hash['contact']['id'].should == contact.id
      hash['contact']['first_name'].should be_nil
    end

    it 'should exclude root' do
      hash = SchemaTools::Hash.from_schema(contact, exclude_root: true)
      hash['last_name'].should == 'Paul'
      hash['_class_name'].should == 'contact'
    end

    it 'has _links on object if exclude root' do
      hash = SchemaTools::Hash.from_schema(contact, exclude_root: true, class_name: :client)
      hash['_links'].length.should == 7
    end

    it 'has _class_name on object if exclude root' do
      hash = SchemaTools::Hash.from_schema(contact, exclude_root: true, class_name: :client)
      hash['_class_name'].should == 'client'
    end
  end

  context 'with nested values referencing a schema' do

    let(:client){Client.new}

    it 'has an empty array if values are missing' do
      hash = SchemaTools::Hash.from_schema(client)
      hash['client']['addresses'].should == []
    end

    it 'has nil if nested object is missing' do
      hash = SchemaTools::Hash.from_schema(client)
      hash['client']['work_address'].should be_nil
    end

    it 'has nested array values' do
      a1 = Address.new
      a1.city = 'Cologne'
      a1.zip = 50733
      client.addresses = [a1]
      hash = SchemaTools::Hash.from_schema(client)
      hash['client']['addresses'].should == [{"address"=>{"city"=>"Cologne", "zip"=>50733}}]
    end

    it 'has nested array values without root' do
      a1 = Address.new
      a1.city = 'Cologne'
      a1.zip = 50733
      client.addresses = [a1]
      hash = SchemaTools::Hash.from_schema(client, exclude_root: true)
      hash['addresses'].should == [{"city"=>"Cologne", "zip"=>50733, "_class_name"=>"address"}]
    end

    it 'has nested object value' do
      a1 = Address.new
      a1.city = 'Cologne'
      a1.zip = 50733
      client.work_address = a1
      hash = SchemaTools::Hash.from_schema(client)
      hash['client']['work_address'].should == {"address"=>{"city"=>"Cologne", "zip"=>50733}}
    end

    it 'has nested object value without root' do
      a1 = Address.new
      a1.city = 'Cologne'
      a1.zip = 50733
      client.work_address = a1
      hash = SchemaTools::Hash.from_schema(client, exclude_root: true)
      hash['work_address'].should == {"city"=>"Cologne", "zip"=>50733, "_class_name"=>"address"}
    end

    it 'has nested oneOf type object ' do
      contact = Contact.new
      contact.first_name = 'Pit'

      i = OneOfDefinition.new
      i.person = contact

      hash = SchemaTools::Hash.from_schema(i, exclude_root: true)
      hash['person']['first_name'].should == 'Pit'
      hash['person']['_class_name'].should == 'contact'
    end

  end

  context 'with plain nested values' do

    let(:lead){Lead.new}
    before :each do
      lead.links_clicked = ['2012-12-12', '2012-12-15', '2012-12-16']
      conversion = Conversion.new
      conversion.from = 'whatever'
      conversion.to = 'whatever'
      lead.conversion = conversion
      @hash = SchemaTools::Hash.from_schema(lead)
    end
    after :each do
      SchemaTools::Reader.registry_reset
    end

    it 'should create array with values' do
      @hash['lead']['links_clicked'].should == lead.links_clicked
    end

    it 'should create object with values' do
      @hash['lead']['conversion']['from'].should == lead.conversion.from
      @hash['lead']['conversion']['to'].should == lead.conversion.to
    end

  end

  context 'with links' do
    let(:client){Client.new}
    before :each do
      client.first_name = 'Peter'
      client.id = 'SomeID'
    end
    after :each do
      SchemaTools::Reader.registry_reset
    end

    it 'has links' do
      hash = SchemaTools::Hash.from_schema(client)
      hash['links'].length.should == 7
    end

    it 'should prepend base_url' do
      hash = SchemaTools::Hash.from_schema(client, base_url: 'http://json-hell.com')
      hash['links'].first['href'].should include( 'http://json-hell.com')
    end

    it 'should replace placeholders' do
      client.id = 123
      hash = SchemaTools::Hash.from_schema(client, base_url: 'http://json-hell.com')
      hash['links'].last['href'].should == 'http://json-hell.com/clients/123/Peter'
    end

  end
end

