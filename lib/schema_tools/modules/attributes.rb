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
        def has_schema_attrs(schema, opts={})
          reader = opts[:reader] || SchemaTools::Reader
          schema = reader.read(schema, opts[:path])
          # make getter / setter
          schema[:properties].each do |key, val|
            # getter
            define_method key do
              schema_attrs[key.to_sym]
            end
            #setter
            unless val[:readonly]
              define_method "#{key}=" do |value|
                schema_attrs[key.to_sym] = value
              end
            end
          end
        end

      end # ClassMethods

    end
  end
end