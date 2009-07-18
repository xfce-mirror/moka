module Moka
  module Component
    module Auth
      def initialize_authentication
        use Rack::Session::Cookie
        
        Warden::Manager.serialize_into_session do |maintainer| 
          maintainer.username 
        end
        
        Warden::Manager.serialize_from_session do |username| 
          Maintainer.find_by_username(username) 
        end
        
        Warden::Manager.before_failure do |env, opts|
          env['REQUEST_METHOD'] = 'POST'
        end
        
        Warden::Strategies.add(:maintainer) do 
          def valid?
            params['username'] and params['password']
          end
        
          def authenticate!
            maintainer = Maintainer.authenticate(params['username'], params['password'])
            maintainer.nil? ? fail!("Authentication failed") : success!(maintainer)
          end
        end
        
        use Warden::Manager do |manager|
          manager.default_strategies :maintainer
          manager.failure_app = Moka
        end
      end

      module Helpers
        def requires_authentication
          redirect '/login' unless env['warden'].authenticated?
        end
      end
            
      def self.registered(app)
        app.get '/login/?' do
          erb :auth_login
        end

        app.post '/login/?' do
          env['warden'].authenticate!
          redirect '/'
        end
    
        app.get '/logout/?' do
          env['warden'].logout
          redirect '/'
        end
      end
    end
  end
end
