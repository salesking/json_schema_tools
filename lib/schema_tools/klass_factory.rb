# encoding: utf-8
require 'active_support/core_ext/string/inflections'
module SchemaTools
  class KlassFactory

    class << self

      # Build classes from schema inside the given namespace. Uses all classes
      # found in schema path:
      # @example
      #
      # First set a global schema path:
      #     SchemaTools.schema_path = File.expand_path('../fixtures', __FILE__)
      #
      # Bake classes from all schema.json found
      #     SchemaTools::KlassFactory.build
      #
      # Go use it
      #     client = Client.new organisation: 'SalesKing'
      #     client.valid?
      #     client.errors.should be_blank
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
        # bake classes
        schemata.each do |schema|
          klass_name = schema['name'].classify
          next if namespace.const_defined?(klass_name, false)
          klass = namespace.const_set(klass_name, Class.new)
          klass.class_eval do
            include SchemaTools::Modules::Attributes
            include ActiveModel::Conversion
            include SchemaTools::Modules::Validations # +naming + transl + conversion
            has_schema_attrs schema['name'], reader: reader
            validate_with schema['name'], reader:reader
            getter_names = schema['properties'].select{|name,prop| !prop['readonly'] }.keys.map { |name| name.to_sym}
            attr_accessor *getter_names

            def initialize(attributes = {})
              attributes.each do |name, value|
                send("#{name}=", value)
              end
            end

            def persisted?; false end
          end
        end
      end

    end
  end
end