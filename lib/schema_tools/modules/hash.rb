# encoding: utf-8
require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'

module SchemaTools
  module Modules
    module Hash

      # Create a Hash with the available (api)object attributes defined in the
      # according schema properties. This is the meat of the
      # object-to-api-markup workflow
      #
      # === Example
      #  obj = Invoice.new(:title =>'hello world', :number=>'4711')
      #
      #  obj_hash = SchemaTools::Hash.from_schema(obj, 'v1.0')
      #   => { 'invoice' =>{'title'=>'hello world', 'number'=>'4711' } }
      #
      #  obj_hash = Schema.to_hash_from_schema(obj, 'v1.0', :fields=>['title'])
      #   => { 'invoice' =>{'title'=>'hello world' } }
      #
      #  obj_hash = Schema.to_hash_from_schema(obj, 'v1.0', :class_name=>:document)
      #   => { 'document' =>{'title'=>'hello world' } }
      #
      # === Parameter
      # obj<Object>:: An ruby object which is returned as hash
      # version<String>:: the schema version, must be a valid folder name see
      # #self.read
      # opts<Hash{Symbol=>Mixed} >:: additional options
      #
      # ==== opts Parameter
      # class_name<String|Symbol>:: Name of the class to use as hash key. Should be
      # a lowered, underscored name and it MUST have an existing schema file.
      # Use it to override the default, which is obj.class.name
      # fields<Array[String]>:: Fields/properties to return. If not set all
      # schema's properties are used.
      #
      # === Return
      # <Hash{String=>{String=>Mixed}}>:: The object as hash:
      # { invoice =>{'title'=>'hello world', 'number'=>'4711' } }
      # @param [Object] obj
      # @param [Object] opts
      def from_schema(obj, opts={})
        fields = opts[:fields]
        # get objects class name without inheritance
        real_class_name = obj.class.name.split('::').last.underscore
        class_name =  opts[:class_name] || real_class_name

        return obj if ['array', 'hash'].include? class_name

        data = {}
        # get schema
        schema = SchemaTools::Reader.read(class_name)
        # iterate over the defined schema fields
        schema['properties'].each do |field, prop|
          next if fields && !fields.include?(field)
          if prop['type'] == 'array'
            data[field] = [] # always set an empty array
            if rel_objects = obj.send( field )
              rel_objects.each do |rel_obj|
                data[field] << to_hash_from_schema(rel_obj, version)
              end
            end
          elsif prop['type'] == 'object' # a singular related object
            data[field] = nil # always set empty val
            if rel_obj = obj.send( field )
              #dont nest field to prevent => client=>{client=>{data} }
              data[field] = to_hash_from_schema(rel_obj, version)
            end
          else # a simple field is only added if the object knows it
            data[field] = obj.send(field) if obj.respond_to?(field)
          end
        end
        hsh = { "#{class_name}" => data }
        #add links if present
        links = parse_links(obj, schema)
        links && hsh['links'] = links
        hsh
      end

      # Parse the link section of the schema by replacing {id} in urls
      # === Returns
      # <Array[Hash{String=>String}]>::
      # <nil>:: no links present
      def parse_links(obj, schema)
        links = []
        schema['links'] && schema['links'].each do |link|
          links << { 'rel' => link['rel'], 'href' => link['href'].gsub(/\{id\}/, "#{obj.id}") }
        end
        links.uniq
        # return links only if not empty
        links.empty? ? nil : links
      end

    end
  end
end