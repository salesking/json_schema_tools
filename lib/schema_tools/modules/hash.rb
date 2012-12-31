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
      #
      #  obj = Invoice.new(:title =>'hello world', :number=>'4711')
      #
      #  obj_hash = SchemaTools::Hash.from_schema(obj)
      #   => { 'invoice' =>{'title'=>'hello world', 'number'=>'4711' } }
      #
      #  obj_hash = Schema.to_hash_from_schema(obj, fields: ['title'])
      #   => { 'invoice' =>{'title'=>'hello world' } }
      #
      #  obj_hash = Schema.to_hash_from_schema(obj, class_name: :document)
      #   => { 'document' =>{'title'=>'hello world' } }
      #
      # @param [Object] obj which is returned as hash
      # @param [Hash{Symbol=>Mixed}] opts additional options
      # @options opts [String|Symbol] :class_name used as hash key. Should be
      # a lowercase underscored name and it MUST have an existing schema file.
      # Use it to override the default, which is obj.class.name
      # @options opts [Array<String>] :fields to return. If not set all schema
      # properties are used.
      # @options opts [String] :path of the schema files overriding global one
      #
      # @return [Hash{String=>{String=>Mixed}}] The object as hash:
      #   { 'invoice' => {'title'=>'hello world', 'number'=>'4711' } }
      #
      def from_schema(obj, opts={})
        fields = opts[:fields]
        # get objects class name without inheritance
        real_class_name = obj.class.name.split('::').last.underscore
        class_name = opts[:class_name] || real_class_name

        data = {}
        # get schema
        schema = SchemaTools::Reader.read(class_name, opts[:path])
        # iterate over the defined schema fields
        schema['properties'].each do |field, prop|
          next if fields && !fields.include?(field)

          if prop['type'] == 'array'

            data[field] = [] # always set an empty array
            if obj.respond_to?( field ) && rel_objects = obj.send( field )
              rel_objects.each do |rel_obj|
                data[field] << if prop['properties'] && prop['properties']['$ref']
                                  #got schema describing the objects
                                  from_schema(rel_obj, opts)
                                else
                                  rel_obj
                                end
              end
            end

          elsif prop['type'] == 'object' # a singular related object

            data[field] = nil # always set empty val
            if obj.respond_to?( field ) && rel_obj = obj.send( field )
              if prop['properties'] && prop['properties']['$ref']
                data[field] = from_schema(rel_obj, opts)
              else
                # NO recursion directly get values from related object. Does
                # NOT allow deeper nesting so you MUST define an own schema to be save
                data[field] = {}
                prop['properties'].each do |fld, prp|
                  data[field][fld] = rel_obj.send(fld) if obj.respond_to?(field)
                end
              end
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