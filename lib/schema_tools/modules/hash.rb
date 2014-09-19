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
      # @param [Object] obj returned as hash
      # @param [Hash{Symbol=>Mixed}] opts additional options
      # @options opts [String|Symbol] :class_name used as hash key. Should be
      # a lowercase underscored name and it MUST have an existing schema file.
      # Use it to override the default, which is obj.class.name. Only used for
      # top-level object NOT nested objects
      # @options opts [Array<String>] :fields to return. If not set all schema
      # properties are used.
      # @options opts [String] :path of the schema files overriding global one
      # @options opts [String] :base_url used in all links
      # @options opts [Boolean] :exclude_root if set objects are not nested under
      # their class name and the object hash gets _links and _class_name inline.
      #
      # @return [Hash{String=>{String=>Mixed}}] The object as hash:
      #   { 'invoice' => {'title'=>'hello world', 'number'=>'4711' } }
      #
      def from_schema(obj, opts={})

        # get objects class name without inheritance
        real_class_name = obj.class.name.split('::').last.underscore
        class_name = opts[:class_name] || real_class_name

        # get schema
        schema = SchemaTools::Reader.read(class_name, opts[:path])
        # iterate over the defined schema fields
        data = parse_properties(obj, schema, opts)
        #get links if present
        links = parse_links(obj, schema, opts)

        if opts[:exclude_root]
          hsh = data
          hsh['_class_name'] = "#{class_name}"
          links && hsh['_links'] = links
        else
          hsh = { "#{class_name}" => data }
          links && hsh['links'] = links
        end
        hsh
      end

      private

      def parse_properties(obj, schema, opts)
        fields = opts[:fields]
        data = {}
        schema['properties'].each do |field, prop|
          next if fields && !fields.include?(field)
          if prop['type'] == 'array'
            opts.delete(:class_name)
            data[field] = parse_list(obj, field, prop, opts)
          elsif prop['type'] == 'object' # a singular related object
            opts.delete(:class_name)
            data[field] = parse_object(obj, field, prop, opts)
          else # a simple field is only added if the object knows it
            data[field] = obj.send(field) if obj.respond_to?(field)
          end
        end
        data
      end

      # Parse the link section of the schema by replacing {id} in urls
      # @param [Object] obj object being parsed
      # @param [Hash] schema
      # @param [Hash] opts
      # @options opts [String] :base_url prepended to link href, WATCH possible double //
      # @return [Array<Hash{String=>String}> | Nil]
      def parse_links(obj, schema, opts={})
        links = []
        schema['links'] && schema['links'].each do |link|
          href = link['href'].dup
          # placeholders: find all {xy}, create replacement ary with
          # values, than replace
          matches = href.scan(/{(\w+)}/) #{abc} => abc
          replaces = []
          matches.each do |match|
            obj_val = obj.send(match[0]) if obj.respond_to?(match[0])
            replaces << ["{#{match[0]}}", obj_val] if obj_val
          end
          replaces.each {|r| href.gsub!(r[0], "#{r[1]}")}
          href = "#{opts[:base_url]}/#{href}" if opts[:base_url]

          links << { 'rel' => link['rel'],
                     'href' => href }
        end
        links.uniq
        # return links only if not empty
        links.empty? ? nil : links
      end

      # Parse a nested array property.
      # @param [Object] obj the object in question
      # @param [String] field name
      # @param [Hash] prop fields schema properties
      # @param [Hash] opts to_schema options
      # @return [Array<Hash{String=>String}>]
      def parse_list(obj, field, prop, opts)
        res = []
        if obj.respond_to?( field ) && rel_objects = obj.send( field )
          rel_objects.each do |rel_obj|
            res << if prop['properties'] #&& prop['properties']['$ref']
                      #got schema describing the objects
                      from_schema(rel_obj, opts)
                    #else
                    #  rel_obj
                    end
          end
        end
        res
      end

      # Parse a nested object property.
      # @param [Object] obj the object in question
      # @param [String] field name
      # @param [Hash] prop fields schema properties
      # @param [Hash] opts to_schema options
      # @return [Array<Hash{String=>String}>]
      def parse_object(obj, field, prop, opts)
        res = nil
        if obj.respond_to?( field ) && rel_obj = obj.send( field )
          if prop['properties'] # && prop['properties']['$ref']
            res = from_schema(rel_obj, opts)
          elsif prop['oneOf']
            # auto-detects which schema to use depending on the rel_object type
            # Simpler than detecting the object type or $ref to use inside the
            # oneOf array
            res = from_schema(rel_obj, opts)
#          else
#            # NO recursion directly get values from related object. Does
#            # NOT allow deeper nesting so you MUST define an own schema to be save
#            res = { }
#            prop['properties'].each do |fld, prp|
#              res[fld] = rel_obj.send(fld) if rel_obj.respond_to?(fld)
#            end
          end
        end
        res
      end

    end
  end
end