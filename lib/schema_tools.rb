require 'json'
require 'schema_tools/version'
require 'schema_tools/modules/read'
require 'schema_tools/modules/hash'
require 'schema_tools/modules/as_schema'
require 'schema_tools/modules/attributes'
require 'schema_tools/modules/validations'
require 'schema_tools/reader'
require 'schema_tools/cleaner'
require 'schema_tools/hash'
require 'schema_tools/klass_factory'
require 'schema_tools/ref_resolver'


module SchemaTools
  SCHEMA_BASE_TYPES = %w(string number integer boolean)
  class << self

    # @param [String] path to schema json files
    def schema_path=(path)
      @schema_path = path
    end
    def schema_path
      @schema_path
    end
  end
end
