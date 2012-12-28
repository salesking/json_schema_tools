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

RSpec.configure do |config|
end

# set global json schema path for examples
SchemaTools.schema_path = File.expand_path('../fixtures', __FILE__)
