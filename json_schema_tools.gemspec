# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'schema_tools/version'

Gem::Specification.new do |s|
  s.name        = 'json_schema_tools'
  s.version     = SchemaTools::VERSION
  s.authors     = ['Georg Leciejewski']
  s.email       = ['gl@salesking.eu']
  s.homepage    = 'https://github.com/salesking/json_schema_tools'
  s.summary     = %q{JSON Schema API tools for server and client side}
  s.description = %q{Want to create or read a JSON Schema powered API? This toolset provides methods to read schemata, render objects as defined in schema, clean parameters according to schema, ...}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rspec'
end
