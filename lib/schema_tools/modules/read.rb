# encoding: utf-8
require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'

module SchemaTools
  module Modules
    # Read schemas into a hash
    module Read

      # Variable remembering already read-in schema's
      # {
      #   :invoice =>{schema}
      #   :credit_note =>{schema}
      #   }
      # }
      # @return [Hash{String=>Hash{Symbol=>HashWithIndifferentAccess}}]
      def registry
        @registry ||= {}
      end

      def registry_reset
        @registry = nil
      end

      # Read a schema and return it as hash. You can supply a path or the
      # global path defined in #SchemaTools.schema_path is used.
      # Schemata are returned from cache(#registry) if present to prevent
      # filesystem round-trips. The cache can be reset with #registry_reset
      #
      # @param [String|Symbol] schema name to be read from schema path directory
      # @param [String|Hash] either the path to retrieve schema_name from,
      #                      or a Schema in Ruby hash form
      # @return[HashWithIndifferentAccess] schema as hash
      def read(schema_name, path_or_schema=nil)
        schema_name = schema_name.to_sym
        return registry[schema_name] if registry[schema_name]

        if path_or_schema.is_a?(::Hash)
          path       = nil
          plain_data = path_or_schema.to_json
        elsif path_or_schema.is_a?(::String) || path_or_schema.nil?
          path       = path_or_schema
          file_path  = File.join(path || SchemaTools.schema_path, "#{schema_name}.json")
        else
          raise ArgumentError, 'Second parameter must be a path or a schema!'
        end

        plain_data ||= File.open(file_path, 'r'){|f| f.read}

        schema = ActiveSupport::JSON.decode(plain_data).with_indifferent_access
        if schema[:extends]
          extends = schema[:extends].is_a?(Array) ? schema[:extends] : [ schema[:extends] ]
          extends.each do |ext_name|
            ext = read(ext_name, path)
            # current schema props win
            schema[:properties] = ext[:properties].merge(schema[:properties])
          end
        end
        _handle_reference_properties schema
        registry[ schema_name ] = schema
      end

      # Read all available schemas from a given path(folder) and return
      # them as array
      #
      # @param [String] path to schema files
      # @return [Array<HashWithIndifferentAccess>] array of schemas as hash
      def read_all(path=nil)
        schemas = []
        file_path = File.join(path || SchemaTools.schema_path, '*.json')
        Dir.glob( file_path ).each do |file|
          schema_name = File.basename(file, '.json').to_sym
          schemas << read(schema_name, path)
        end
        schemas
      end

      def _handle_reference_properties schema
        return unless schema["properties"]
        schema["properties"].each { |key, value|
          next unless value["$ref"]

          json_pointer = value["$ref"]
          values_from_pointer = SchemaTools.load_json_pointer json_pointer
          schema["properties"][key].merge!(values_from_pointer) {|key, old, new| 
            old
          }
          schema["properties"][key].delete("$ref")
        }
      end
    end
  end
end
