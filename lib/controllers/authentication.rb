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
          Moka::Models::Maintainer.get(username)
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
            maintainer.nil? or maintainer.active == false ? fail!("Authentication failed") : success!(maintainer)
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

        def authentication_required(context = nil, roles = ['admin'])
          redirect '/login' unless authentication_finished?

          if (context.is_a? Moka::Models::Project)
            # abort processing the current page if the user is not
            # a maintainer of the project and his/her user roles
            # and the required roles have no elements in common
            unless context.maintainers.include?(authentication_user)
              if not authentication_user.authorized?(roles)
                halt(view(:permission_denied, binding))
              end
            end
          elsif (context.is_a? Moka::Models::Collection)
            # abort processing the current page if the user is not
            # a maintainer of the collection and his/her user roles
            # and the required roles have no elements in common
            unless context.maintainers.include?(authentication_user)
              if not authentication_user.authorized?(roles)
                halt(view(:permission_denied, binding))
              end
            end
          elsif (context.is_a? Moka::Models::Maintainer)
            # abort processing the current page if the user is not
            # the same as the required maintainer and his/her user
            # roles and the required roles have no elements in common
            unless authentication_user == context
              if not authentication_user.authorized?(roles)
                halt(view(:permission_denied, binding))
              end
            end
          else
            # abort processing the current page if the user roles
            # and the required roles have no elements in common
            if not authentication_user.authorized?(roles)
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
          view :login
        end

        app.post '/login/?' do

          maintainer = Moka::Models::Maintainer.get(params['username'])

          if maintainer and maintainer.active == true and maintainer.password == 'invalid'
            maintainer.password = Digest::SHA1.hexdigest(params['password'])
            maintainer.save
            redirect '/'
          end

          env['warden'].authenticate!
          redirect '/'
        end

        app.post '/unauthenticated' do
          view :login_unauthenticated
        end

        app.get '/logout/?' do
          env['warden'].logout
          redirect '/'
        end

        app.get '/login/forgot' do

          view :login_forgot
        end

        app.get '/login/request' do

          view :login_request
        end

        app.get '/login/request/sshinfo' do

          view :login_request_sshinfo
        end

        app.post '/login/request' do
          if params[:username].empty? or params[:realname].empty? or params[:email].empty?
            error_set(:username, 'All fields below are required')
            view :login_request
          elsif not Moka::Models::Maintainer.get(params[:username]).nil?
            error_set(:username, 'This username is already taken')
            view :login_request
          elsif params[:password].empty? or params[:password].length < 6
            error_set(:password, 'The password must be at least 6 characters long.')
            view :login_request
          elsif not params[:password].eql? params[:password2]
            error_set(:password, 'The two passwords you entered did not match.')
            view :login_request
          else
            @maintainer = Moka::Models::Maintainer.create (:username => params[:username])
            @maintainer.email = params[:email]
            @maintainer.realname = params[:realname]
            @maintainer.password = Digest::SHA1.hexdigest(params[:password])
            @maintainer.active = false
            @maintainer.save

            view :login_request_finished
          end
        end
      end
    end
  end
end
