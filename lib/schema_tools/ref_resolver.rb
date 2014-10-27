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
  #
  # @param [String] json_pointer the JSON Pointer expression to evaluate
  # @param [Schema] relative_to if the pointer refers to a local schema, this is this
  # the hash to evaluate it against. If the pointer contains a uri to a
  # referenced schema, an attempt is made to load
  def self.load_json_pointer json_pointer, relative_to = nil
    # JSON Pointer is a big, abandoned WIP and we're going to
    # start by only implementing the part's we need ...
    if nil ==  (json_pointer =~ /^(.*)#(.*)/ )
      raise "invalid json pointer: #{json_pointer}"
    end

    uri     = $1.strip
    pointer = $2
    schema  = {}
    unless uri.empty?
      uri = URI.parse(uri)
      raise "must currently be a relative uri: #{json_pointer}" if uri.absolute?
      # TODO use locale tools instance or base path from global SchemaTools.schema_path
      base_dir = relative_to ? relative_to.absolute_dir : SchemaTools.schema_path
      path = File.join(base_dir, uri.path)
      unless File.exist?(path)
        # try to find in main-dir and subdirs of global schema path and if
        # present a schema's absolute dir
        filename = uri.path.split('/').last
        search_dirs = [File.join(SchemaTools.schema_path, filename),
                       File.join(SchemaTools.schema_path, '**/*', filename)]
        if relative_to
          search_dirs += [ File.join(relative_to.absolute_dir, filename),
                           File.join(relative_to.absolute_dir, '**/*', filename) ]
        end
        recursive_search = Dir.glob(search_dirs)[0]
        # if still not found keep orig path to throw error on open
        path = recursive_search || path
      end
      open (path) {|f| schema = JSON.parse(f.read) }
    end

    return self._retrieve_pointer_from_object pointer, schema
  end


  def self._retrieve_pointer_from_object pointer, object
    # assume path to be the JSONPointer expression:
    #  json/pointer/expression
    # and obj to be the ruby hash representation of the json
    path = pointer.is_a?(Array) ? pointer : pointer.split("/")

    while object != nil && component = path.shift
      prev   = object
      component = component.to_i if object.is_a?(Array) && component =~ /^\d+$/
      object = object[component]
    end

    return object
  end

  end # module
end # module




