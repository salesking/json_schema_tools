module SchemaTools::Resource
  module Destroy
    # DELETE contacts/:id
    def self.add(klass, link, base_url)
      klass.send :define_method, 'destroy' do
        url_path = SchemaTools::Modules::Hash.parse_placeholders(link['href'],{id: self.id})
        connection = Excon.new(base_url)
        opts = {
          method: link['method']|| 'DELETE',
          path: url_path,
        }
        response = connection.request(opts)
        # parse result into self.attributes if result contains obj markup
        # raise
       end
    end
  end
end