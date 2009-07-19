require 'rubygems'

gem 'warden', '0.2.3'
require 'warden'

module Moka
  module Controllers
    module Authentication
      def authentication_initialize
        use Rack::Session::Cookie
        
        Warden::Manager.serialize_into_session do |maintainer| 
          maintainer.username 
        end
        
        Warden::Manager.serialize_from_session do |username| 
          Moka::Models::Maintainer.find_by_username(username) 
        end
        
        Warden::Manager.before_failure do |env, opts|
          env['REQUEST_METHOD'] = 'POST'
        end
        
        Warden::Strategies.add(:maintainer) do 
          def valid?
            params['username'] and params['password']
          end
        
          def authenticate!
            maintainer = Moka::Models::Maintainer.authenticate(params['username'], params['password'])
            maintainer.nil? ? fail!("Authentication failed") : success!(maintainer)
          end
        end
        
        use Warden::Manager do |manager|
          manager.default_strategies :maintainer
          manager.failure_app = Moka::Application
        end
      end

      module Helpers
        def authentication_finished?
          env['warden'].authenticated?
        end

        def authentication_required(context = nil)
          redirect '/login' unless authentication_finished?

          if (context.is_a? Moka::Models::Project)
            p "context is a Project"
            unless context.maintainers.include?(authentication_user)
              halt(view(:permission_denied, binding))
            end
          elsif (context.is_a? Moka::Models::Collection)
            unless context.maintainers.include?(authentication_user)
              halt(view(:permission_denied, binding))
            end
          elsif (context.is_a? String)
            unless authentication_user.roles.include?(context)
              halt(view(:permission_denied, binding))
            end
          else
            redirect '/login'
          end
        end

        def authentication_user
          env['warden'].user
        end
      end
            
      def self.registered(app)
        app.helpers Helpers

        app.get '/login/?' do
          view :auth_login
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
