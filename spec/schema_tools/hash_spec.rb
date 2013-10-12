require 'spec_helper'


describe SchemaTools::Hash do

  context 'from_schema to hash conversion' do

    class Contact
      attr_accessor :first_name, :last_name, :addresses, :id
    end
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
      hash = SchemaTools::Hash.from_schema(contact, class_name: :contact)
      hash['contact']['last_name'].should == 'Paul'
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

    it 'should have _links on object if exclude root' do
      hash = SchemaTools::Hash.from_schema(contact, exclude_root: true, class_name: :client)
      hash['_links'].length.should == 8
    end

    it 'should have _class_name on object if exclude root' do
      hash = SchemaTools::Hash.from_schema(contact, exclude_root: true, class_name: :client)
      hash['_class_name'].should == 'client'
    end
  end

  context 'with nested values referencing a schema' do
    class Client
      attr_accessor :first_name, :id, :addresses,  :work_address
    end
    class Address
      attr_accessor :city, :zip
    end

    let(:client){Client.new}

    it 'should have an empty array if values are missing' do
      hash = SchemaTools::Hash.from_schema(client)
      hash['client']['addresses'].should == []
    end

    it 'should have nil if nested object is missing' do
      hash = SchemaTools::Hash.from_schema(client)
      hash['client']['work_address'].should be_nil
    end

    it 'should have nested array values' do
      a1 = Address.new
      a1.city = 'Cologne'
      a1.zip = 50733
      client.addresses = [a1]
      hash = SchemaTools::Hash.from_schema(client)
      hash['client']['addresses'].should == [{"address"=>{"city"=>"Cologne", "zip"=>50733}}]
    end

    it 'should have nested array values without root' do
      a1 = Address.new
      a1.city = 'Cologne'
      a1.zip = 50733
      client.addresses = [a1]
      hash = SchemaTools::Hash.from_schema(client, exclude_root: true)
      hash['addresses'].should == [{"city"=>"Cologne", "zip"=>50733, "_class_name"=>"address"}]
    end

    it 'should have nested object value' do
      a1 = Address.new
      a1.city = 'Cologne'
      a1.zip = 50733
      client.work_address = a1
      hash = SchemaTools::Hash.from_schema(client)
      hash['client']['work_address'].should == {"address"=>{"city"=>"Cologne", "zip"=>50733}}
    end

    it 'should have nested object value without root' do
      a1 = Address.new
      a1.city = 'Cologne'
      a1.zip = 50733
      client.work_address = a1
      hash = SchemaTools::Hash.from_schema(client, exclude_root: true)
      hash['work_address'].should == {"city"=>"Cologne", "zip"=>50733, "_class_name"=>"address"}
    end

  end

  context 'with plain nested values' do
    # see fixtures/lead.json
    class Lead < Contact
      attr_accessor :links_clicked, :conversion
    end

    class Conversion
      attr_accessor :from, :to
    end

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
end

