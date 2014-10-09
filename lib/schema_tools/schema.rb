

module SchemaTools
  # Internal representation of a Schema. This is basically a wrapper around a
  # HashWithIndifferentAccess ( for historical purposes ) as well as information
  # concerning where the Schema was loaded from in order to resolve relative paths.

  class Schema
    # Schema may be initialized with either a filename or a hash
    def initialize name_or_hash
      case name_or_hash
      when(::Hash) 
        @hash = name_or_hash.with_indifferent_access
      when(::String)
        src = File.open(name_or_hash, 'r'){|f| f.read}
        self.absolute_filename= name_or_hash
        decode src
      end
      handle_extends
      resolve_refs
    end

    ##################################################################################
    # Wrappers for internal Hash
    ##################################################################################

    def [] key
      @hash[key]
    end

    def []= key, value
      @hash[key] = value
    end 
    
    def merge schema
      raise :hell unless schema[:properties]
      @hash.merge schema[:properites]
    end
    
    def empty?
      @hash.empty?
    end

    def keys
      @hash.keys
    end

    def == other
      case other
        when (::Hash)
          return other.with_indifferent_access == hash
        when (ActiveSupport::HashWithIndifferentAccess)
          return other == hash
        when (Schema)
          return other.hash == hash
        else
          return false
      end
    end

    ##################################################################################
    # /Wrappers for internal Hash
    ##################################################################################


    # set the filename the Schema was loaded from
    def absolute_filename= fn
      @absolute_filename = File.absolute_path(fn)
      @absolute_dir      = File.dirname (@absolute_filename)
    end

    # retrieve the filename the Schema was loaded from or nil if the Schema
    # was constructed from a Hash
    def absolute_filename
      @absolute_filename || nil
    end

    # retrieve the base directory against which refs should be resolved.
    def absolute_dir
      @absolute_dir || SchemaTools.schema_path
    end



    protected

    def hash
      @hash
    end

    private

    def decode src
      @hash = ActiveSupport::JSON.decode(src).with_indifferent_access
    end

    def handle_extends
      if self[:extends]
        extends = self[:extends].is_a?(Array) ? self[:extends] : [ self[:extends] ]
        extends.each do |ext_name|
          ext = Reader.read(ext_name, absolute_dir)
          # current schema props win
          self[:properties] = ext[:properties].merge(self[:properties])
        end
      end
    end

    # Merge referenced property definitions into the given schema.
    # e.g. each object has an updated_at field which we define in a single
    # location(external file) instead of repeating the property def in each
    # schema.
    # any hash found along the way is processed recursively, we look for a
    # "$ref" param and resolve it. Other params are checked for nested hashes
    # and those are processed.
    # @param [HashWithIndifferentAccess] schema - single schema
    def resolve_refs schema = nil
      schema ||= @hash
      
       def resolve_reference hash
          json_pointer = hash["$ref"]
          values_from_pointer = RefResolver.load_json_pointer json_pointer, self
          hash.merge!(values_from_pointer) { |key, old, new| old }
          hash.delete("$ref")
        end

      keys = schema.keys # in case you are wondering: RuntimeError: can't add a new key into hash during iteration
      keys.each do |k|
        v = schema[k]
        if k == "$ref"
          resolve_reference schema
        elsif v.is_a?(ActiveSupport::HashWithIndifferentAccess)
          resolve_refs v
        end
      end

    end
  end
end
  
