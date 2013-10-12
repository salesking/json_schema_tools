require 'active_support/concern'
module SchemaTools
  module Modules
    # Add schema properties to a class by including this module and defining from
    # which schema to inherit attributes.
    module AsSchema
      extend ActiveSupport::Concern
      # convert this class to a schema markup. The schema is derived from
      # has_schema_attrs definition(if available) or from given options
      def as_schema_json(opts={})
        ActiveSupport::JSON.encode(as_schema_hash(opts))
      end

      def as_schema_hash(opts={})
        # detect schema name from class method, else class name or opts is used.
        if self.class.schema_name
          opts[:class_name] ||= self.class.schema_name
        end
        SchemaTools::Hash.from_schema(self, opts)
      end

      module ClassMethods
        def use_schema(name)
          @schema_name = name
        end

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
