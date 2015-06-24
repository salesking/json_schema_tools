module SchemaTools
  module Modules
    module ObjectProperties
      PROPERTIES = 'properties'
      ALLOF = 'allOf'
      ANYOF = 'anyOf'
      ONEOF = 'oneOf'
      PROPERTY_CONTAINERS = [ PROPERTIES, ALLOF, ANYOF, ONEOF ]

      def all_properties(schema_hash, properties_hash = ActiveSupport::HashWithIndifferentAccess.new )
        return schema_hash unless PROPERTY_CONTAINERS.any? { |container| schema_hash[container] }

        PROPERTY_CONTAINERS.reduce(properties_hash) do |properties, container|
          if schema_hash[container]
            if schema_hash[container].respond_to?(:key?)
              properties.merge!(schema_hash[container])
            elsif schema_hash[container].kind_of?(Array)
              schema_hash[container].each do |sub_schema|
                properties.merge!(all_properties(sub_schema))
              end
            end
          end
          properties
        end
      end
    end
  end
end
