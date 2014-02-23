require 'active_support/concern'
module SchemaTools
  module Modules
    # Add schema properties to a class by using has_schema_attrs to define from
    # which schema to inherit attributes.
    # @example
    #
    #   class Contact
    #     has_schema_attrs :contact
    #   end
    #   Contact.schema_name #=> contact
    #   Contact.as_json
    #   Contact.as_hash
    #   Contact.schema  #=> json schema hash
    module Attributes
      extend ActiveSupport::Concern
      include SchemaTools::Modules::AsSchema

      def schema_attrs
        @schema_attrs ||= {}
      end

      def schema
        self.class.schema
      end

      module ClassMethods

        # @param [Symbol|String] schema name
        # @param [Hash<Symbol|String>] opts
        # @options opts [String] :path schema path
        # @options opts [SchemaTools::Reader] :reader instance, instead of global reader/registry
        def has_schema_attrs(schema_name, opts={})
          reader          = opts[:reader] || SchemaTools::Reader
          schema_location = opts[:path]   || opts[:schema]
          # remember schema + name on class level
          self.schema( reader.read(schema_name, schema_location) )
          self.schema_name(schema_name)
          # make getter / setter
          self.schema[:properties].each do |key, prop|
            define_method(key) { schema_attrs[key] }
            define_method("#{key}=") { |value| schema_attrs[key] = value } unless prop[:readonly]
          end
          #TODO parse links ?? or do it in resource module
        end

        # @param [Hash] schema_hash
        def schema(schema_hash=nil)
          @schema = schema_hash if schema_hash
          @schema
        end

      end
    end
  end
end
