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
            define_method("#{key}=") { |value| schema_attrs[key] = value } unless prop[:readonly]
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
            # set values to raw schema attributes, even if there are no setters
            # assuming this objects comes from a remote site
            field_props = self.schema['properties']["#{key}"]
            conv_val = if val.nil?
                         val
                       elsif field_props['type'] == 'string'
                         if field_props['format'] == 'date'
                          Date.parse(val) # or be explicit? Date.strptime('2001-02-03', '%Y-%m-%d')
                         elsif field_props['format'] == 'date-time'
                           Time.parse(val) # vs Time.strptime
                         else
                          "#{val}"
                         end
                       elsif field_props['type'] == 'integer'
                         val.to_i
                       else # rely on preceding call e.g from_json for boolean, number
                         val
                       end
                      # TODO if val is a hash / array => look for nested class & cast
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

      end
    end
  end
end
