# encoding: utf-8
require 'excon'

module SchemaTools
  module Modules
    #
    # Ideas:
    # class WithRemote
    #   has_schema_attrs :contact
    #   has_schema_links
    #   has_schema_links link_key: 'links',
    #                    base_url: 'https://demo.salesking.eu'
    # end
    # Class.connection(pass, usr)
    # obj.new(params)
    #
    # obj.before_find(request)
    # obj.after_find(request)
    #
    # obj.save => put/patch
    # obj.find(id)   => rel: self "/contacts/{id}"
    # obj.find_all(page:2, per_page:100, filter{q:'search'})   => rel: instances "/contacts?filter[name]"
    #
    # obj.save        => true/false
    # obj.save!       => raise
    #
    module Resource
      extend ActiveSupport::Concern
      include SchemaTools::Modules::Attributes

      def connection
        @connection || self.class.connection
      end
      # remember last request
      def request=(req)
        @request = req
      end

      def persisted?
        self.id.present?
      end


      module ClassMethods

        # relies on has_schema_attrs which set the schema before
        def has_schema_links(opts={})
          links_key = opts[:link_key] || 'links' # proc.call()
          base_url = opts[:base_url] || nil
          return unless schema[links_key]
          schema[links_key].each do |link|
            next unless link['rel'] && link['href']
            build_methods_from_link(link, base_url)
            if link['properties']
              # handle_link_properties
            end
          end
        end

        def build_methods_from_link(link, base_url=nil)
          case link['rel']
            when 'self'
              SchemaTools::Resource::Find.add(self, link, base_url)
              # find class Method
              # Contact.find(id)
            when 'instances'
              # find_all class Method
              SchemaTools::Resource::FindAll.add(self, link, base_url)
            when 'destroy'
              SchemaTools::Resource::Destroy.add(self, link, base_url)
            when 'update'
              # PUT contacts/id
              SchemaTools::Resource::Save.add(self, link, base_url)
            when 'create'
              #SchemaTools::Resource::Create.add(self, link, base_url)
            else
              # any defaults ??
          end
        end

      end
    end
  end
end
