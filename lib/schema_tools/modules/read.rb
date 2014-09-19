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
      # @return[HashWithIndifferentAccess|Nil] schema as hash, nil if schema is not an object
      def read(schema_name, path_or_schema=nil)
        schema_name = schema_name.to_sym
        return registry[schema_name] if registry[schema_name]

        if path_or_schema.is_a?(::Hash)
          path       = nil
          plain_data = path_or_schema.to_json
        elsif path_or_schema.is_a?(::String) || path_or_schema.nil?
          path       = path_or_schema
          file_path  = File.join(path || SchemaTools.schema_path, "#{schema_name}.json")
          unless File.exist?(file_path)
            # check if file exists else try to find first real path in sub-dirs
            recursive_search = Dir.glob( File.join(SchemaTools.schema_path, '**/*', "#{schema_name}.json"))[0]
            # use only if we found something, else keep path which will throw error on file.open later
            file_path = recursive_search || file_path
          end
        else
          raise ArgumentError, 'Second parameter must be a path or a schema!'
        end

        plain_data ||= File.open(file_path, 'r'){|f| f.read}

        schema = ActiveSupport::JSON.decode(plain_data).with_indifferent_access
        # only import object definitions, shared property definitions are handled separate
        return unless schema[:type] == 'object'
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

      # Read all available schemas from a given path(folder +subfolders) and
      # return the found object definitions them as array. Also populates the
      # registry
      #
      # @param [String] path to schema files
      # @return [Array<HashWithIndifferentAccess>] array of schemas as hash
      def read_all(path=nil)
        schemas = []
        file_paths = if path
                       [File.join(path, '*.json')]
                     else
                       [ File.join( SchemaTools.schema_path, '*.json'),
                         File.join( SchemaTools.schema_path, '**/*', '*.json')
                       ]
                     end

        Dir.glob( file_paths ).each do |file|
          schema_name = File.basename(file, '.json').to_sym
          schemas << read(schema_name, path)
        end
        schemas.compact!
        schemas
      end

      # Merge referenced property definitions into the given schema.
      # e.g. each object has an updated_at field which we define in a single
      # location(external file) instead of repeating the property def in each
      # schema.
      # any hash found along the way is processed recursively, we look for a
      # "$ref" param and resolve it. Other params are checked for nested hashes
      # and those are processed.
      # @param [HashWithIndifferentAccess] schema - single schema
      def _handle_reference_properties(schema)

        def resolve_reference hash
          json_pointer = hash["$ref"]
          values_from_pointer = RefResolver.load_json_pointer json_pointer
          hash.merge!(values_from_pointer) { |key, old, new| old }
          hash.delete("$ref")
        end

        keys = schema.keys # in case you are wondering: RuntimeError: can't add a new key into hash during iteration
        keys.each do |k|
          v = schema[k]
          if k == "$ref"
            resolve_reference schema
          elsif v.is_a?(ActiveSupport::HashWithIndifferentAccess)
            _handle_reference_properties v
          end
        end

      end # _handle_reference_properties
    end
  end
end
