# encoding: utf-8
require 'simplecov'
require 'active_support'

SimpleCov.start do
  root File.join(File.dirname(__FILE__), '..')
  add_filter "/bin/"
  add_filter "/spec/"
end

$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'json_schema_tools'
require 'test_helpers'

RSpec.configure do |config|
end

I18n.enforce_available_locales = false if I18n.respond_to?('enforce_available_locales=')
# set global json schema path for examples
SchemaTools.schema_path = File.join(fixture_path,'schemata')

puts "Testing with ActiveModel Version: #{ActiveModel.version rescue ActiveModel::VERSION::STRING}"
