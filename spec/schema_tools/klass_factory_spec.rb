require 'spec_helper'

class TestNamespaceKlass
  # for schema classes
end

module TestNamespaceModule

end

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