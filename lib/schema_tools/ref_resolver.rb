# encoding: utf-8
module SchemaTools

  # 
  # super basic resolving of JSON Pointer stuff in order
  # to be able to load $ref parameter.
  #
  # $refs in JSON Schema are defined in JSON Pointer syntax:
  # http://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-07

  def SchemaTools.load_json_pointer json_pointer
    # JSON Pointer is a big, abandoned WIP and we're going to 
    # start by only implementing the part's we need ...
    if ! json_pointer =~ /^(.*)#(.*)/ 
      raise "invalid json pointer: #{}"
    end

    uri     = $1
    pointer = $2
    json    = nil

    open(uri) {|f|  json = JSON.parse(f.read) }

    
    return SchemaTools._retrieve_pointer_from_object json, pointer
  end

 
  def SchemaTools._retrieve_pointer_from_object pointer, object
    # assume path to be the JSONPointer expression:
    #  json/pointer/expression
    # and obj to be the ruby hash representation of the json
    
    path = pointer.is_a?(Array) ? pointer : pointer.split("/")

    while object != nil && component = path.shift
      prev   = object
      component = component.to_i if object.is_a?(Array) && component =~ /^\d+$/
      object = object[component]
    end
    
#    # if we did not find anything and the last element of the 
#    # pointer was a number this might have been a reference into
#    # an array.
#    if prev && prev.is_a?(::Array)
#      # if the last component in the path was a number
#      if component =~ /^\d+$/ 
#        idx    = component.to_i
#        object = prev[idx]
#        return SchemaTools._retrieve_pointer_from_object path, object
#      end
#    end

    return object
  end

end # module




