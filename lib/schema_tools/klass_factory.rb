# encoding: utf-8
require 'active_support/core_ext/string/inflections'
module SchemaTools
  class KlassFactory

    class << self

      # Build ruby classes from a schema with getter/setter methods for all
      # properties and validation. Uses all classes(json files) found in global
      # schema path or you can add a custom path.
      # A namespace can be given under which the classes will be created.
      # @example
      #
      # First set a(global) schema path:
      #     SchemaTools.schema_path = File.expand_path('../fixtures', __FILE__)
      #
      # Build classes from all json files in schema path
      #     SchemaTools::KlassFactory.build
      #
      # Go use them
      #     client = Client.new organisation: 'SalesKing'
      #     client.valid?
      #     client.errors.should be_blank
      # With custom options:
      #     SchemaTools::KlassFactory.build namespace: MyModule,
      #                                     path: 'custom/path/to_json_schema'
      # @param [Hash] opts
      # @options opts [SchemaTools::Reader] :reader to use instead of global one
      # @options opts [String] :path to schema files instead of global one
      # @options opts [String|Symbol|Module] :namespace of the new classes e.g. MyCustomNamespace::MySchemaClass
      def build(opts={})
        reader = opts[:reader] || SchemaTools::Reader
        schemata = reader.read_all( opts[:path] || SchemaTools.schema_path )
        namespace = opts[:namespace] || Object
        namespace = "#{namespace}".constantize if namespace.is_a?(String) || namespace.is_a?(Symbol)
        # bake classes
        schemata.each do |schema|
          next if !schema['name'] or namespace.const_defined?(schema['name'].classify, false)
          build_class(schema, namespace, reader)
        end
      end

      # @param [Object] schema single json schema
      # @param [Constant] namespace for the new class
      # @param [SchemaTools::Reader] reader set into new class for validation and attributes
      def build_class(schema, namespace, reader)
        klass_name = schema['name'].classify
        klass = namespace.const_set(klass_name, Class.new)
        klass.class_eval do
          include SchemaTools::Modules::Attributes
          include ActiveModel::Conversion
          include SchemaTools::Modules::Validations # +naming + transl + conversion
          has_schema_attrs schema['name'], reader: reader
          validate_with schema['name'], reader:reader
          getter_names = schema['properties'].select{|name,prop| !prop['readonly'] }
                                             .keys.map { |name| name.to_sym}
          attr_accessor *getter_names

          def initialize(attributes = {})
            attributes.each do |name, value|
              send("#{name}=", value)
            end
          end

          def persisted?; false end
        end # class
      end

      # @param [Object] name
      def namespace(name)

      end

    end
  end
end
