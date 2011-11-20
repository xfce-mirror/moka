require 'net/http'
require 'net/https'

module Moka
  module Middleware
    class Identica
      attr_accessor :username
      attr_accessor :password
      attr_accessor :group

      def initialize(app)
        @app = app

        yield self if block_given?
      end

      def call(env)
        request = Rack::Request.new(env)
        env['identica'] = self
        status, headers, body = @app.call(env)
        response = Rack::Response.new(body, status, headers)
        response.to_a
      end

      def post(status)
        url = URI.parse('https://identi.ca/api/statuses/update.json')
    
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true

        http.start do |http|
          header = {
            'User-Agent' => 'Moka',
            'X-Twitter-Client' => 'Moka',
            'X-Twitter-Client-Version' => 'Unknown',
            'X-Twitter-Client-URL' => 'http://git.xfce.org/jannis/moka',
          }

          request = Net::HTTP::Post.new(url.path)
          request.basic_auth(username, password)
          request.set_form_data({'status' => status})

          http.request(request)
        end
      end
    end
  end
end
