module SchemaTools::Resource
  module Save
    # POST contacts/id
    def self.add(klass, link, base_url)
      klass.send :define_method, 'save' do
        url_path = SchemaTools::Modules::Hash.parse_placeholders(link['href'],{id: self.id})
        connection = Excon.new(base_url)
        opts = {
          method: link['method']|| 'POST',
          path: url_path,
        }
        response = connection.request(opts)
        # parse result into self.attributes if result contains obj markup
        # raise
       end
    end
  end
end