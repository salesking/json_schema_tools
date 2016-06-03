require 'active_support/concern'
module SchemaTools
  module Modules
    # Extend a class so it can be rendered as json from a named schema
    module AsSchema
      extend ActiveSupport::Concern

      # convert object to a schema markup.
      # @param [Hash{Symbol=>Mixed}] opts passed on to #SchemaTools::Hash.from_schema
      # @return [String] json
      def as_schema_json(opts={})
        JSON.generate(as_schema_hash(opts))
      end

      # The object as hash with fields detected from its schema.
      # The schema name is derived from:
      # * options[:class_name]
      # * has_schema_attrs definition(if used)
      # * the underscored class name
      # @param [Hash{Symbol=>Mixed}] opts passed on to #SchemaTools::Hash.from_schema
      # @return [Hash]
      def as_schema_hash(opts={})
        # detect schema name from class method, else class name or opts is used.
        if self.class.schema_name
          opts[:class_name] ||= self.class.schema_name
        end
        SchemaTools::Hash.from_schema(self, opts)
      end

      module ClassMethods
        # Get or set the schema name used
        # @param [Symbol|String] name
        def schema_name(name=nil)
          @schema_name = name if name
          @schema_name
        end
      end

    end
  end
end
