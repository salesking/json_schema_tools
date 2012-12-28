# encoding: utf-8
module SchemaTools
  # Read schemas into a hash.
  # Use as instance if you have multiple different schema sources/versions
  # which may collide. Go for class methods if you have globally unique schemata
  class Reader
    include SchemaTools::Modules::Read
    extend SchemaTools::Modules::Read
  end
end