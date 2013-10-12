require 'active_support/concern'
module SchemaTools
  module Modules
    # Add schema properties to a class by including this module and defining from
    # which schema to inherit attributes.
    module Attributes
      extend ActiveSupport::Concern

      def schema_attrs
        @schema_attrs ||= {}
      end

      module ClassMethods

        # @param [Symbol|String] schema name
        # @param [Hash<Symbol|String>] opts
        # @options opts [String] :path schema path
        # @options opts [SchemaTools::Reader] :reader instance, instead of global reader/registry
        def has_schema_attrs(schema_name, opts={})
          reader          = opts[:reader] || SchemaTools::Reader
          schema_location = opts[:path]   || opts[:schema]
          schema          = reader.read(schema_name, schema_location)
          # remember name on class level
          self.schema_name = schema_name
          # make getter / setter
          schema[:properties].each do |key, val|
            # getter
            define_method key do
              schema_attrs[key]
            end
            #setter
            unless val[:readonly]
              define_method "#{key}=" do |value|
                #TODO validations?
                schema_attrs[key] = value
              end
            end
          end
        end

        # Add getter setter for schema name -> also done in as_schema
        if !method_defined?(:schema_name)
          def schema_name
            @schema_name
          end
          def schema_name=(name)
            @schema_name = name
          end
        end

      end

    end
  end
end
