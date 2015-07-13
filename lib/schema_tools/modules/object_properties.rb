module SchemaTools
  module Modules
    module ObjectProperties
      PROPERTIES = 'properties'
      ALLOF = 'allOf'
      ANYOF = 'anyOf'
      ONEOF = 'oneOf'
      PROPERTY_CONTAINERS = [ PROPERTIES, ALLOF, ANYOF, ONEOF ]

      def all_properties(schema_hash)
        return schema_hash unless PROPERTY_CONTAINERS.any? { |container| schema_hash[container] }

        PROPERTY_CONTAINERS.reduce(ActiveSupport::HashWithIndifferentAccess.new) do |properties, container|
          if schema_hash[container]
            if schema_hash[container].kind_of?(Array)
              properties.merge!(parse_sub_schemas(schema_hash[container]))
            else
              properties.merge!(schema_hash[container])
            end
          end
          properties
        end
      end

      def parse_sub_schemas(schema_array)
        schema_array.reduce(ActiveSupport::HashWithIndifferentAccess.new) do |properties, sub_schema|
          properties.merge!(all_properties(sub_schema))
        end
      end
    end
  end
end
