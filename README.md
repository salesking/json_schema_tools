# JSON Schema Tools

{<img src="https://secure.travis-ci.org/salesking/json_schema_tools.png?branch=master" alt="Build Status" />}[http://travis-ci.org/salesking/json_schema_tools]

Set of tools to help working with JSON Schemata:

* read schema files into a ruby hash
* add schema properties to a class
* convert a model(class instance) into it's schema markup
* clean parameters according to a schema (e.g. in an api controller)


## Usage

Hook the gem into your app

    gem 'json_schema_tools'

### Read Schema

Before the fun begins with any of the tools one or multiple JSON schema files
must be read(into a hash). So first provide a base path where the .json files
can be found:

    SchemaTools.schema_path = '/path/to/schema-json-files'

No you can read a single or multiple schemas:

    schema = SchemaTools::Reader.read :client
    # read all *.json files in schema path
    schemata = SchemaTools::Reader.read_all
    # see schema cached in registry
    SchemaTools::Reader.registry[:client]

Read files from another path?

    schema = SchemaTools::Reader.read :client, 'my/path/to/json-files'
    schemata = SchemaTools::Reader.read_all 'my/path/to/json-files'

Don't like the global path and registry? Go local:

    reader = SchemaTools::Reader.new
    reader.read :client, 'from/path'
    reader.registry


## Object to schema markup

A schema provides a (public) contract about an object definition. It is
therefore a common task to convert an internal object to its schema version.
Before the object can be represented as a json string, it is converted to a
hash containing only the properties(keys) from its schema definition:

Following uses client.json schema(same as client.class name) from global
schema_path and adds properties to the clients_hash simply calling
client.send('property-name'):

  peter = Client.new name: 'Peter'
  client_hash = SchemaTools::Hash.from_schema(peter)
  # to_json is up to you .. or your rails controller

TODO: explain Options for parsing:
* custom class name
* fields include/exclude
* custom schema name

## Test

  bundle install
  bundle exec rake spec


Copyright 2012-1013, Georg Leciejewski, MIT License
