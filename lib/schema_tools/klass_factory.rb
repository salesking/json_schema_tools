# encoding: utf-8
require 'active_support/core_ext/string/inflections'
module SchemaTools
  class KlassFactory

    class << self

      # Build classes from schema inside the given namespace. Uses all classes
      # found in schema path
      #
      # @param [Hash] opts
      # @options opts [SchemaTools::Reader] :reader to use instead of global one
      # @options opts [SchemaTools::Reader] :path to schema files instead of global one
      # @options opts [SchemaTools::Reader] :namespace of the new classes e.g. MyCustomNamespace::MySchemaClass
      def build(opts={})
        reader = opts[:reader] || SchemaTools::Reader
        schemata = reader.read_all( opts[:path] || SchemaTools.schema_path )
        namespace = opts[:namespace] || Object
        if namespace.is_a?(String) || namespace.is_a?(Symbol)
          namespace = "#{namespace}".constantize
        end

        schemata.each do |schema|
          klass_name = schema['name'].classify
          next if namespace.const_defined?(klass_name, false)
          klass = namespace.const_set(klass_name, Class.new)
          klass.class_eval do
            include SchemaTools::Modules::Attributes
            has_schema_attrs schema['name'], reader: reader
          end
        end
      end

    end
  end
end