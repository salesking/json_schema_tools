require 'json'
require 'schema_tools/version'
require 'schema_tools/core_ext/object'
require 'schema_tools/modules/read'
require 'schema_tools/modules/hash'
require 'schema_tools/modules/as_schema'
require 'schema_tools/modules/attributes'
require 'schema_tools/modules/resource'
require 'schema_tools/modules/validations'
require 'schema_tools/reader'
require 'schema_tools/cleaner'
require 'schema_tools/hash'
require 'schema_tools/klass_factory'

require 'schema_tools/resource/destroy'
require 'schema_tools/resource/find'
require 'schema_tools/resource/find_all'
require 'schema_tools/resource/save'


module SchemaTools
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