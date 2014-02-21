require 'spec_helper'

class TestNamespaceKlass
  # namespace for schema classes
end

module TestNamespaceModule; end

describe SchemaTools::KlassFactory do

  after :each do
    SchemaTools::Reader.registry_reset

    # try cleaning objs
    Object.send :remove_const, 'Client' if Object.const_defined? 'Client'
    TestNamespaceKlass.send :remove_const, 'Client' if TestNamespaceKlass.const_defined? 'Client'
    TestNamespaceModule.send :remove_const, 'Client' if TestNamespaceModule.const_defined? 'Client'
  end

  context 'class building' do
    it 'should build from class name' do
      SchemaTools::KlassFactory.build
      expect { Client.new }.to_not raise_error
      expect { Lead.new }.to_not raise_error
    end

  end

  context 'from json' do
    it 'should build object' do
      SchemaTools::KlassFactory.build
      json_str = ActiveSupport::JSON.encode(client: { organisation: 'Ruby Fun'})

      client = Client.new json: json_str
      #client = Client.from_json json_str
      client.organisation.should == 'Ruby Fun'
    end
  end

  context 'with validations' do
    it 'should add validations' do
      SchemaTools::KlassFactory.build
      client = Client.new
      client.valid?
      client.errors[:organisation][0].should include 'blank'
    end

    it 'should build with params' do
      SchemaTools::KlassFactory.build
      client = Client.new organisation: 'SalesKing'
      client.valid?
      client.errors.should be_blank
    end

    it 'should validate number maximum and minimum' do
      SchemaTools::KlassFactory.build
      client = Client.new cash_discount: 100, organisation: 'SalesKing'
      client.should be_valid
      #to big
      client.cash_discount = 101
      client.valid?
      client.errors.full_messages[0].should include('less than or equal to')
      # to small
      client.cash_discount = -1
      client.valid?
      client.errors.full_messages[0].should include('greater than or equal to')
    end

    it 'should raise with invalid params' do
      SchemaTools::KlassFactory.build
      expect { Client.new id: 'SalesKing' }.to raise_error NoMethodError
    end

  end

  context 'class building with namespace' do

    after :each do
    end

    it 'should build from class name' do
      SchemaTools::KlassFactory.build(namespace: TestNamespaceKlass)
      expect { TestNamespaceKlass::Client.new }.to_not raise_error
    end

    it 'should build from class as string' do
      SchemaTools::KlassFactory.build(namespace: 'TestNamespaceKlass')
      expect { TestNamespaceKlass::Client.new }.to_not raise_error
    end
    it 'should build from module name' do
      SchemaTools::KlassFactory.build(namespace: TestNamespaceModule)
      expect { TestNamespaceModule::Client.new }.to_not raise_error
    end

    it 'should build from module name as string' do
      SchemaTools::KlassFactory.build(namespace: 'TestNamespaceModule')
      expect { TestNamespaceModule::Client.new }.to_not raise_error
    end

  end
end