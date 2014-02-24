# encoding: utf-8
require 'excon'

# by http://blog.jayfields.com/2007/10/ruby-defining-class-methods.html
class Object # http://whytheluckystiff.net/articles/seeingMetaclassesClearly.html
  def define_class_method name, &blk
    (class << self; self; end).instance_eval { define_method name, &blk }
  end
end

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
    # Class.conection(pass, usr)
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

      def request
        @request
        #@connection || self.class.connection
      end
      def request=(req)
        @request = req
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
              # define class Method
              # Contact.find(id)
              define_class_method 'find' do |*args|
                id, request_opts = args[0], args[1]
                url_path = SchemaTools::Modules::Hash.parse_placeholders(link['href'],{id: id})
                method = link['method'] || 'GET'
                # setup request
                connection = Excon.new(base_url)
                opts = {
                  method: link['method']|| 'DELETE',
                  path: url_path,
                }
                # before_find(request)
                response = connection.get
                # parse result into self.attributes if result contains obj markup
                # raise
                # GET contacts/id
                # self.response = response
                # parse result into self.attributes
                # after_find(request) use excon notify callbacks
                # new_obj = self.new params
                # or raise
                return self
               end
            when 'instances'
            when 'destroy'
              define_method 'destroy' do
                url_path = SchemaTools::Modules::Hash.parse_placeholders(link['href'],{id: self.id})
                method =
                # DELETE contacts/id
                connection = Excon.new(base_url)
                opts = {
                  method: link['method']|| 'DELETE',
                  path: url_path,
                }
                response = connection.get
                # parse result into self.attributes if result contains obj markup
                # raise
               end
            when 'update'
              define_method 'save' do
                url = SchemaTools::Modules::Hash.parse_placeholders(link['href'],{id: self.id})
                method = link['method']|| 'PUT'
                # PUT contacts/id
                # parse result into self.attributes if result contains obj markup
                # raise
               end
            when 'create'
            else
          end
        end

      end
    end
  end
end
