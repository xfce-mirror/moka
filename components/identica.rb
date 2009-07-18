require 'net/http'
require 'net/https'

module Moka
  module Component
    module Identica
      def initialize_identica
      end

      module Helpers
        def identica_announce_release(release, url)
          status = "#{release.project.name} #{release.version} released: #{url} !Xfce"

          url = URI.parse('https://identi.ca/api/statuses/update.json')

          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true
          
          http.start do |http|
            header = {
              'User-Agent' => "Moka on #{Configuration.get.moka_url}",
              'X-Twitter-Client' => 'Moka',
              'X-Twitter-Client-Version' => 'Unspecified',
              'X-Twitter-Client-URL' => Configuration.get.moka_url,
            }

            request = Net::HTTP::Post.new(url.path)

            request.basic_auth(Configuration.get.identica['username'],
                               Configuration.get.identica['password'])
            request.set_form_data({'status' => status})
          
            http.request(request)
          end
        end
      end
    end
  end
end
