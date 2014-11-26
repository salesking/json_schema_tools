# JSON Schema Tools

[![Build Status](https://travis-ci.org/salesking/json_schema_tools.png?branch=master)](https://travis-ci.org/salesking/json_schema_tools)

Toolbox to work with JSON Schema in Ruby:

* blow up classes from schema
* object.as_schema_json conversion
* object.valid? validations with object.errors

Simply use full blown classes or customize the bits and pieces:

* add schema properties to an existing class
* add validations to an existing class
* clean parameters e.g. in an api controller
* customize json output, object namespaces, used schema

## Usage

Hook the gem into your app

    gem 'json_schema_tools'

Quickstart assuming you have schema definitions [like those](https://github.com/salesking/sk_api_schema/tree/master/json/v1.0) in place.

```ruby
# add schema directory to the search path
SchemaTools.schema_path = '/path/to/schema-json-files'
# blow up classes for each schema file
SchemaTools::KlassFactory.build

# init with params (assumes a contact.json definition)
contact = Contact.new first_name: 'Barry', last_name: 'Cade'
# use setters/getters
contact.first_name = 'Ahr'
# validations derived from property definitions
contact.valid?
contact.errors.full_messages
```

## Schema handling

Before the fun begins, with any of the tools, one or multiple JSON schema(files)
must be available. A schema is converted into a ruby hash and for convenience is
cached into a registry (global or per reader object). Globals are initialized
once e.g on program start. A reader object allows to handle schemata in dynamic
ways.

When using the global SchemaTools reader simply provide a base path to the
schema files and you are done.

```ruby
SchemaTools.schema_path = '/path/to/schema-json-files'
```

Read a single schema:

```ruby
schema = SchemaTools::Reader.read :client
```

Read a schema from an existing Ruby hash:

```ruby
schema = SchemaTools::Reader.read :client, { ... }
```

Read multiple schemas, all *.json files in schema path

```ruby
schemata = SchemaTools::Reader.read_all
```

Schemata are cached in registry

```ruby
SchemaTools::Reader.registry[:client]
```

Read files from a custom path?

```ruby
schema = SchemaTools::Reader.read :client, 'my/path/to/json-files'
schemata = SchemaTools::Reader.read_all 'my/path/to/json-files'
```

Don't like the global path and registry? Go local:

```ruby
reader = SchemaTools::Reader.new
reader.read :client, 'from/path'
reader.registry
```

Get a schema as plain ruby hash with all $refs de-referenced

```ruby
SchemaTools::Reader.read_all
client_schema = SchemaTools::Reader.registry[:client]
schema_hash = client_schema.to_h
```

## Object to JSON  - from Schema

As you probably know such is done e.g in rails via object.as_json. While using
this might be simple, it has a damn big drawback: There is no transparent
contract about the data-structure, as rails simply uses all fields defined in the
database(ActiveRecord model). One side-effect: With each migration you are f***ed

A schema provides a public contract about an object definition. Therefore an
internal object is converted to it's public(schema) version on delivery(API access).
First the object is converted to a hash containing only the properties(keys)
from its schema definition. Afterwards it is a breeze to convert this hash into
JSON, with your favorite generator.

Following uses client.json schema, detected from peter.class name.underscore => "client",
inside the global schema_path and adds properties to the clients_hash by simply calling
client.send('property-name'):

```ruby
class Client < ActiveRecord::Base
  include SchemaTools::Modules::AsSchema
end

peter = Client.new name: 'Peter'
peter.as_schema_json
#=> "client":{"id":12, "name": "Peter", "email":"",..}

peter.as_hash
#=> "client"=>{"id"=>12, "name"=> "Peter", "email"=>"",..}
```

The AsSchema module is a tiny wrapper for following low level method:

```ruby
paul = Contact.new name: 'Paul'
contact_hash = SchemaTools::Hash.from_schema(paul)
#=> "contact"=>{"id"=>12, "name"=> "Paul",..}
# to_json is up to you .. or your rails controller
```

### Customise Output JSON / Hash

Following examples show options to customize the resulting json or hash. Of
course they can be combined.

Only use some fields e.g. to save bandwidth

```ruby
peter.as_schema_json(fields:['id', 'name'])
#=> "client":{"id":12, "name": "Peter"}
```

Use a custom schema name e.g. to represent a client as contact. Assumes you also
have a schema named contact.json

```ruby
peter.as_schema_json(class_name: 'contact')
```

Set a custom schema path

```ruby
peter.as_schema_json( path: 'path-to/json-files/')
```

By default the object hash has the class name (client) and the link-section on
root level. This divides the data from the available methods and makes a clear
statement about the object type(it's class).
If you don't want to traverse that one extra level you can exclude the root
and move the data one level up. See how class name and links are available
inline:

```ruby

peter.as_schema_json( exclude_root: true )

#=> {"id":12, "name"=> "Peter",
#    "_class_name":"client",
#    "_links":[ .. ] }
```

Of course the low level hash method also supports all of these options:

```ruby
client_hash = SchemaTools::Hash.from_schema(peter, fields:['id', 'name'])
#=> "client"=>{"id"=>12, "name"=> "Peter"}
```

## Object from JSON

On any remote site you'll need to instantiate new objects from an incoming json
string. Let's assume a contact class which you need for incoming contact json
data.  (Example taken from attributes_spec.rb)

```ruby
SchemaTools.schema_path = '/path/to/schema-json-files-with-contact-def'
class Contact
  include SchemaTools::Modules::Attributes
  has_schema_attrs :contact
end

json_str = '{"id": "123456", "last_name": "Meier","first_name": "Peter"}
c = Contact.from_json(json_str)
c.id #=> 123456

```


## Parameter cleaning

Hate people spamming your api with wrong object fields? Use the Cleaner to
check incoming params.

For example in a client controller

```ruby
def create
  SchemaTools::Cleaner.clean_params!(:client, params[:client])
  # params[:client] now only has keys defined as writable in client.json schema
  #..create and save client
end
```

## Object attributes from Schema

Add methods, defined in schema properties, to an existing class.
Very useful if you are building a API client and don't want to manually add
methods to you local classes .. like people NOT using JSON schema

```ruby
class Contact
  include SchemaTools::Modules::Attributes
  has_schema_attrs :client
end

contact = Client.new
contact.last_name = 'Rambo'
# raw access
contact.schema_attrs
# to json
contact.as_schema_json
```

## Classes from Schema - KlassFactory

Use the KlassFactory to directly create classes, with all attributes from a
schema. Instead of adding attributes to an existing class like in above example.
The classes are named after each schema's [name] (in global path).
So lets assume you have a 'client.json' schema with a name attribute in it, for
the following examples:

```ruby
SchemaTools::KlassFactory.build
client = Client.new first_name: 'Heinz'
client.name = 'Schultz'
client.valid?
client.errors.full_messages
```

Rather like a namespace? Good idea, but don't forget the class or module must
be defined.

```ruby
module SalesKing; end
SchemaTools::KlassFactory.build namespace: SalesKing
client = SalesKing::Client.new
```

Add a custom schema reader most likely useful in conjunction with a custom path

```ruby
reader = SchemaTools::Reader.new
SchemaTools::KlassFactory.build reader: reader, path: HappyPdf::Schema.path
```

## $ref

Provides some basic support for JSON Pointer. JSON Pointer expressions must reference local
files and must contain a fragment identifier, i.e.

     ./some_include.json#properties

is a resolvable pointer, while

     http://example.com/public_schema.json

is not.


## Real world examples

* [DocTag ruby gem](https://github.com/docTag/doctag_rb) and [DocTag json-schema](https://github.com/docTag/doctag_json_schema)
* [SalesKing json schema](https://github.com/salesking/sk_api_schema)
* [HappyPdf json schema](https://github.com/happyPDF/happypdf_json_schema) .. api gem will follow
* .. Your UseCase here

## Test

Only runs on Ruby 1.9 and by default uses most recent ActiveModel version (>3).

    bundle install
    rake spec

Testing with different ActiveModel / ActiveSupport Versions:

    RAILS_VERSION=3.1 bundle install
    rake spec
    # or if already installed
    RAILS_VERSION=4 rake spec

The RAILS_VERSION switch sets the version of the gems in the Gemfile and is only
useful in test env.

# Credits

* [Andy Nicholson](https://github.com/anicholson)

Copyright 2012-1013, Georg Leciejewski, MIT License
