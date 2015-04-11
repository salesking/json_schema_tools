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
    #   Contact.schema_name     #=> contact
    #   Contact.as_schema_json  #=> json string
    #   Contact.as_hash         #=> ruby hash
    #   Contact.schema          #=> json schema hash
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

          self.schema= reader.read(schema_name, schema_location)
          self.schema_name(schema_name)
          # make getter / setter methods
          self.schema[:properties].each do |key, prop|
            define_method(key) { schema_attrs[key] }
            define_method("#{key}=") { |value| schema_attrs[key] = value } unless prop['readOnly']
          end
        end

        # Create a new object from a json string or a ruby hash (already created
        # from json string). Auto-detects nesting by checking for a hash key
        # with the same name as the schema_name:
        #
        #     class Contact
        #       include SchemaTools::Modules::Attributes
        #       has_schema_attrs :contact
        #     end
        #     c = Contact.from_json('{ "id": "123456",  "last_name": "Meier" }')
        #     c.id #=>123456
        #     c = Contact.from_json( {'contact'=>{ "id=>"123456", "last_name"=>"Meier" }} )
        #
        # @param [String|Hash{String=>Mixed}] json string or hash
        def from_json(json)
          hash = JSON.parse(json)
          from_hash(hash)
        end

        # Create a new object from a ruby hash (e.g parsed from json string).
        # Auto-detects nesting by checking for a hash key with the same name as
        # the schema_name:
        #
        #     class Contact
        #       include SchemaTools::Modules::Attributes
        #       has_schema_attrs :contact
        #     end
        #     c = Contact.from_hash( {'contact'=>{ "id=>"123456", "last_name"=>"Meier" }} )
        #     c.id #=>123456
        #
        # @param [Hash{String=>Mixed}] json string or hash
        # @param [Object] obj if you want to update an existing objects
        # attributes. e.g during an update
        def from_hash(hash, obj=nil)
          # test if hash is nested and shift up
          if hash.length == 1 && hash["#{schema_name}"]
            hash = hash["#{schema_name}"]
          end
          obj ||= new
          hash.each do |key, val|
            next unless obj.respond_to?(key)
            conv_val = nil
            # set values to raw schema attributes, even if there are no setters
            # assuming this objects comes from a remote site
            field_props = self.schema['properties']["#{key}"]
            field_type = field_props['type']
            unless val.nil?
              case field_type
              when 'string'
                conv_val = process_string_type(field_props['format'], val)
              when 'integer'
                conv_val = val.to_i
              when 'object'
                conv_val = process_object_type(key, val)
              when 'array'
                conv_val = process_array_type(key, val)
              else
                conv_val = val
              end
            end

            obj.schema_attrs["#{key}"] = conv_val
          end
          obj
        end

        # @param [Hash] schema_hash
        def schema= schema_hash
          @schema = schema_hash
        end
        def schema
          @schema
        end

        private

        def process_string_type(field_format, value)
          if field_format == 'date'
            Date.parse(value) # or be explicit? Date.strptime('2001-02-03', '%Y-%m-%d')
          elsif field_format == 'date-time'
            Time.parse(value) # vs Time.strptime
          else
           value.to_s
          end
        end

        def process_object_type(field_name, value)
          if nested_class(field_name)
            nested_class(field_name).from_hash(value)
          else
            value
          end
        end

        def process_array_type(field_name, value)
          if nested_class(field_name.to_s.singularize)
            value.map do |element|
              nested_class(field_name.to_s.singularize).from_hash(element)
            end
          else
            value
          end
        end

        def nested_class(field_name)
          "#{base_class}::#{field_name.to_s.camelize}".safe_constantize
        end

        def base_class
          self.to_s.deconstantize
        end
      end
    end
  end
end
