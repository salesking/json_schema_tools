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

        def has_schema_attrs(schema)
          schema = SchemaTools::Reader.read(schema)
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

      end # ClassMethods

    end
  end
end