require 'active_support/concern'
require 'active_model'
# comment single files bcs. AM requires lazy and in rails 4 names have changed!
# left them in for reference
#require 'active_model/validations'
#require 'active_model/naming'
#require 'active_model/translation'
#require 'active_model/conversion'

module SchemaTools
  module Modules
    # Add schema properties to a class by including this module and defining from
    # which schema to inherit attributes.
    module Validations
      extend ActiveSupport::Concern
      include ActiveModel::Conversion
      include ActiveModel::Validations

      # Runs all the validations within the specified context.
      # @return [Boolean] true if  no errors are found, false otherwise
      def valid?
        output = super
        errors.empty? && output
      end

      module ClassMethods

        # @param [Symbol|String] schema name
        # @param [Hash<Symbol|String>] opts
        # @options opts [String] :path schema path
        # @options opts [SchemaTools::Reader] :reader instance, instead of global reader/registry
        def validate_with(schema, opts={})
          reader = opts[:reader] || SchemaTools::Reader
          schema = reader.read(schema, opts[:path])
          # create validation methods
          schema[:properties].each do |key, val|
            is_required =  schema['required'] && schema['required'].include?("#{key}")
            validates_length_of key, validate_length_opts(val, is_required) if val['maxLength'] || val['minLength']
            validates_presence_of key if is_required
            validates_numericality_of key, validate_number_opts(val, is_required) if val['type'] == 'number' || val['type'] == 'integer'
            #TODO array minItems, max unique,  null, string
            # format: date-time, regex color style, email,uri,  ..
          end
        end

        def validate_length_opts(attr, is_required=false)
          opts = {}
          opts[:within] = attr['minLength']..attr['maxLength'] if attr['minLength'] && attr['maxLength']
          opts[:maximum] = attr['maxLength'] if attr['maxLength'] && !attr['minLength']
          opts[:minimum] = attr['minLength'] if attr['minLength'] && !attr['maxLength']
          opts[:allow_blank] = true unless is_required
          opts
        end

        # @param [Hash<String>] attr property values
        def validate_number_opts(attr, is_required=false)
          opts = {}
          opts[:allow_blank] = true unless is_required
          # those vals should not be set both in one property
          opts[:greater_than_or_equal_to] = attr['minimum'] if attr['minimum'].present?
          opts[:less_than_or_equal_to] = attr['maximum'] if attr['maximum'].present?
          opts[:less_than] = attr['exclusiveMinimum'] if attr['exclusiveMinimum'].present?
          opts[:greater_than] = attr['exclusiveMaximum'] if attr['exclusiveMaximum'].present?
          opts
        end

      end # ClassMethods

    end
  end
end