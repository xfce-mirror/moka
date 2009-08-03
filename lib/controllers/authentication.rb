require 'rubygems'
require 'pp'

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
            if Moka::Models::Maintainer.use_http_auth?
              env.has_key?('REMOTE_USER')
            else
              params['username'] and params['password']
            end
          end
        
          def authenticate!
            if Moka::Models::Maintainer.use_http_auth?
              maintainer = Moka::Models::Maintainer.find_by_username(env['REMOTE_USER'])
            else
              maintainer = Moka::Models::Maintainer.authenticate(params['username'], params['password'])
            end
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
          if Moka::Models::Maintainer.use_http_auth?
            env['warden'].authenticate!
          end
          env['warden'].authenticated?
        end

        def authentication_required(context = nil, role = 'admin')
          redirect '/login' unless authentication_finished?

          if (context.is_a? Moka::Models::Project)
            unless context.maintainers.include?(authentication_user)
              unless authentication_user.roles.include?(role)
                halt(view(:permission_denied, binding))
              end
            end
          elsif (context.is_a? Moka::Models::Collection)
            unless context.maintainers.include?(authentication_user)
              unless authentication_user.roles.include?(role)
                halt(view(:permission_denied, binding))
              end
            end
          elsif (context.is_a? Moka::Models::Maintainer)
            unless authentication_user == context
              unless authentication_user.roles.include?(role)
                halt(view(:permission_denied, binding))
              end
            end
          else
            unless authentication_user.roles.include?(role)
              halt(view(:permission_denied, binding))
            end
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
          
          maintainer = Moka::Models::Maintainer.find_by_username(params['username'])

          if maintainer and maintainer.password == 'invalid'
            maintainer.password = Digest::SHA1.hexdigest(params['password'])
            maintainer.save
            redirect '/'
          end

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
