module SchemaTools::Resource
  module Find
    # GET contacts/:id
    def self.add(klass, link, base_url)
      klass.define_class_method 'find' do |*args|
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
        response = connection.request(opts)
        # parse result into self.attributes if result contains obj markup
        # raise
        # after_find(request) use excon notify callbacks
        # new_obj = self.new params
        # or raise
        #return self
      end
    end
  end
end