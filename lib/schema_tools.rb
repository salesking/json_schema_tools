require 'json'
require 'schema_tools/version'
require 'schema_tools/modules/read'
require 'schema_tools/modules/hash'
require 'schema_tools/reader'
require 'schema_tools/hash'


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