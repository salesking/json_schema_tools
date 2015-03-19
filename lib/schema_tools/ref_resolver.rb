# encoding: utf-8

require 'json'
require 'uri'

module SchemaTools
  class RefResolver

    #
    # super basic resolving of JSON Pointer stuff in order
    # to be able to load $ref parameter.
    #
    # $refs in JSON Schema are defined in JSON Pointer syntax:
    # http://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-07
    # JSON Pointer is a big, abandoned WIP and we're going to start by only
    # implementing the part's we need ...
    #
    # @param [String] json_pointer the JSON Pointer expression to evaluate
    # @param [Schema] relative_to if the pointer refers to a local schema, this is this
    # the hash to evaluate it against. If the pointer contains a uri to a
    # referenced schema, an attempt is made to load
    def self.load_json_pointer(json_pointer, relative_to = nil, stack)
      if json_pointer[/#/] && json_pointer[0] != '#'
        # hash-symbol syntax pointing to a property of a schema. client.json#properties
        raise "invalid json pointer: #{json_pointer}" unless json_pointer =~ /^(.*)#(.*)/
        uri, pointer = json_pointer.match(/^(.*)#(.*)/).captures
      elsif json_pointer[0] == '#'
        raise "invalid internal json ref: #{json_pointer}" unless stack.include?(json_pointer) && json_pointer.size != 1
        internal_reference = true
      else
        uri = json_pointer
      end
      raise "invalid uri pointer: #{json_pointer}" if !internal_reference && uri.empty?
      schema  = {}
      if internal_reference
        path = json_pointer.split('#')[1]
        ref = path.split('/')
        props = relative_to
        ref.each { |i| props = props[i]}
        schema = {ref.last => props}
      else
        uri = URI.parse(uri)
        raise "must currently be a relative uri: #{json_pointer}" if uri.absolute?
        # TODO use local tools instance or base path from global SchemaTools.schema_path
        base_dir = relative_to ? relative_to.absolute_dir : SchemaTools.schema_path
        path = find_local_file_path(base_dir, uri.path, relative_to)
        open (path) {|f| schema = JSON.parse(f.read) }
      end
      if pointer
        self._retrieve_pointer_from_object(pointer, schema)
      else
        schema
      end
    end

    # @param [String] base_dir
    # @param [String] path relative file name with optional sub-path prefix:
    # contact.json, ./contacts/client.json
    # @param [Schema] relative_to If the pointer contains a uri to a referenced
    # schema, an attempt is made to load it from the relatives absolute dir
    def self.find_local_file_path(base_dir, file_path, relative_to=nil)
      path = File.join(base_dir, file_path)
      return path if File.exist?(path)

      # try to find in main-dir and subdirs of global schema path and if present
      # a schema's absolute dir
      filename = file_path.split('/').last
      search_dirs = [File.join(SchemaTools.schema_path, filename),
                     File.join(SchemaTools.schema_path, '**/*', filename)]
      if relative_to
        search_dirs += [ File.join(relative_to.absolute_dir, filename),
                         File.join(relative_to.absolute_dir, '**/*', filename) ]
      end
      recursive_search = Dir.glob(search_dirs)[0]
      # if still not found return orig path to throw error on open
      recursive_search || path
    end


    def self._retrieve_pointer_from_object(pointer, object)
      # assume path to be the JSONPointer expression:
      #  json/pointer/expression
      # and obj to be the ruby hash representation of the json
      path = pointer.is_a?(Array) ? pointer : pointer.split("/")

      while object != nil && component = path.shift
        component = component.to_i if object.is_a?(Array) && component =~ /^\d+$/
        object = object[component]
      end

      return object
    end

  end
end
