module SchemaTools::Resource
  module FindAll
    # GET contacts
    def self.add(klass, link, base_url)
      klass.define_class_method 'find_all' do |*args|
        request_opts = args[0] # filter params?
        url_path = link['href']
        connection = Excon.new(base_url)
        opts = {
          method: link['method']|| 'GET',
          path: url_path,
        }
        response = connection.request(opts)
        # parse result into self.attributes if result contains obj markup
        # raise
       end
    end
  end
end