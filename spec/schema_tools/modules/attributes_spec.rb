require 'spec_helper'

class TestClient
  include SchemaTools::Modules::Attributes
  has_schema_attrs :client
  end

class TestContact
  include SchemaTools::Modules::Attributes
  has_schema_attrs :contact
end

class Numbers
  include SchemaTools::Modules::Attributes
  has_schema_attrs :numbers, :schema => schema_as_ruby_object
end

class WorkAddress
  include SchemaTools::Modules::Attributes
  has_schema_attrs :address
end

class ItemCollection
  include SchemaTools::Modules::Attributes
  has_schema_attrs :item_collection
end

class Item
  include SchemaTools::Modules::Attributes
  has_schema_attrs :item
end

describe SchemaTools::Modules::Attributes do

  context 'included' do
    subject { TestClient.new }

    it 'should add getter methods' do
      subject.should respond_to(:last_name)
    end

    it 'should add setter methods' do
      subject.should respond_to('first_name=')
    end

    it 'should not add setter for readOnly properties' do
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

  context '.from_json' do

    it 'creates new object' do
      str = load_fixture_data('contact_plain.json')
      hash = JSON.parse(str)
      obj = TestContact.from_json(str)
      expect(obj.id).to eq hash['id']
      expect(obj.organisation).to eq hash['organisation']
      expect(obj.contact_source).to eq hash['contact_source']
      expect(obj.first_name).to eq hash['first_name']
      expect(obj.last_name).to eq hash['last_name']
    end

    it 'creates new object from nested response' do
      str = load_fixture_data('contact_nested.json')
      hash = JSON.parse(str)['contact']
      obj = TestContact.from_json(str)
      expect(obj.id).to eq hash['id']
      expect(obj.organisation).to eq hash['organisation']
      expect(obj.contact_source).to eq hash['contact_source']
      expect(obj.first_name).to eq hash['first_name']
      expect(obj.last_name).to eq hash['last_name']
    end
  end

  context '.from_hash' do

    it 'creates new object from hash' do
      hash = JSON.parse(load_fixture_data('contact_nested.json'))
      obj = TestContact.from_hash(hash)
      expect(obj.id).to eq hash['contact']['id']
      expect(obj.organisation).to eq hash['contact']['organisation']
      expect(obj.contact_source).to eq hash['contact']['contact_source']
      expect(obj.first_name).to eq hash['contact']['first_name']
      expect(obj.last_name).to eq hash['contact']['last_name']
    end

    it 'converts strings' do
      hash = { organisation: 123}
      obj = TestContact.from_hash(hash)
      expect(obj.organisation).to eq '123'
    end

    it 'converts integers' do
      hash = { click_count: '23'}
      obj = TestContact.from_hash(hash)
      expect(obj.click_count).to eq 23
    end

    it 'converts dates' do
      hash = { birthday: "1975-11-17"}
      obj = TestContact.from_hash(hash)
      expect(obj.birthday.class).to eq Date
    end

    it 'skips nil values' do
      hash = { created_at: nil}
      obj = TestClient.from_hash(hash)
      expect(obj.created_at).to eq nil
    end

    it 'converts datetime' do
      hash = { created_at: "2014-12-06T04:30:26+01:00"}
      obj = TestClient.from_hash(hash)
      expect(obj.created_at.class).to eq Time
      # expect(obj.created_at.zone).to eq 'CET' # fails on travis-ci .. strange
      expect(obj.created_at.year).to eq 2014

      hash = { created_at: "2014-12-04T10:39:50.000Z"}
      obj = TestClient.from_hash(hash)
      expect(obj.created_at.zone).to eq 'UTC'
      expect(obj.created_at.hour).to eq 10
    end

    it 'makes nested objects if there are nested hashes' do
      hash = {work_address: {}}
      obj = TestClient.from_hash(hash)
      expect(obj.work_address).to be_an_instance_of(WorkAddress)
    end

    it 'makes nested array of objects if there are nested arrays of hashes' do
      hash = {items: [{}, {}]}
      obj = ItemCollection.from_hash(hash)
      expect(obj.items.first).to be_an_instance_of(Item)
    end

    it 'updates an object' do
      obj = TestContact.from_hash( {first_name: 'Frieda'} )
      expect(obj.first_name).to eq 'Frieda'
      expect(obj.last_name).to eq nil

      TestContact.from_hash({first_name: 'Paul', last_name: 'Hulk'}, obj)
      expect(obj.first_name).to eq 'Paul'
      expect(obj.last_name).to eq 'Hulk'
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

    it 'should not add setter for readOnly properties' do
      subject.should_not respond_to('id=')
    end
  end
end

