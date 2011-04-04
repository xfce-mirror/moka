module Moka
  module Controllers
    module Request
      include Moka::Models

      def self.registered(app)
        app.get '/request' do
          
          view :request
        end

        app.get '/request/sshinfo' do
          
          view :request_sshinfo
        end

        app.post '/request' do

          view :request_finished
        end
      end
    end
  end
end
