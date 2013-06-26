# encoding: utf-8
require 'active_support/core_ext/string/inflections'
module SchemaTools

  module Modules
  module KlassMethods
    def from_json(json_str)
      obj = self.new
      params= ActiveSupport::JSON.decode(json_str).with_indifferent_access
      # check for nesting {"contact":{props} }
      if params[self.name.singularize.downcase]
        params = params[self.name.singularize.downcase]
      end
      # assign values raw
      obj.schema_attrs
      params.each { |key, val|
        obj.schema_attrs[key.to_sym] = val
      }
      obj
    end
  end
  end

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
            extend SchemaTools::Modules::KlassMethods
            include ActiveModel::Conversion
            include SchemaTools::Modules::Validations # +naming + transl + conversion
            has_schema_attrs schema['name'], reader: reader
            validate_with schema['name'], reader:reader

            getter_names = schema['properties'].select{|name,prop| !prop['readonly'] }.keys.map { |name| name.to_sym}
            attr_accessor *getter_names

            def initialize(attributes = {})
              json_str = attributes.delete(:json)
              if !json_str
                attributes.each do |name, value|
                  send("#{name}=", value)
                end
              else #if attributes.is_a?( String)
                params = ActiveSupport::JSON.decode(json_str).with_indifferent_access
                # check for nesting {"contact":{props} }
                if params[self.class.name.singularize.downcase]
                  params = params[self.class.name.singularize.downcase]
                end
                # assign values raw
                self.schema_attrs
                params.each { |key, val|
                  (@schema_attrs || schema_attrs)[key.to_sym] = val

                }
              end

            end

            def persisted?; false end
          end
        end
      end

    end
  end


end