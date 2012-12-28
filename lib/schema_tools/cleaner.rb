# encoding: utf-8

module SchemaTools
  class Cleaner

    class << self

      # Clean a hash before a new object is created from it. Can be used in
      # your ruby controllers where new objects are created from a params-hash
      # Directly CHANGES incoming params-hash!
      #
      # @param [String|Symbol] obj_name of the object/schema
      # @param [Hash{String|Symbol=>Mixed}] params properties for the object
      # @param [Hash] opts
      # @options opts [Array<String|Symbol>] :keep properties not being kicked
      # even if defined as readonly
      def clean_params!(obj_name, params, opts={})
        schema = SchemaTools::Reader.read(obj_name)
        setters = []
        # gather allowed properties
        schema[:properties].each{ |k,v| setters << k if !v['readonly'] }
        setters += opts[:keep] if opts[:keep] && opts[:keep].is_a?(Array)
        # kick readonly
        params.delete_if { |k,v| !setters.include?("#{k}")  }
        #convert to type in schema
        params.each do |k,v|
          if schema[:properties]["#{k}"]['type'] == 'string' && !v.is_a?(String)
            params[k] = "#{v}"
          end
        end
      end

    end
  end
end