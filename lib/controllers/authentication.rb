require 'rubygems'
require 'logger'
require 'warden'
require 'pony'
require 'time'

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

        def maintainer_forgot(username, token = nil)
          maintainer = Moka::Models::Maintainer.get(username)
          expired = 3600 * 2;

          if maintainer and maintainer.active == true
            if token
              if (Time.now.to_f - maintainer.token_stamp) > expired or
                 maintainer.token.empty? or
                 not maintainer.token.eql? token
                return nil
              end
            else
              # check if the old token has not expired yet. this to avoid
              # spam from annoying people
              if (Time.now.to_f - maintainer.token_stamp) < expired
                return nil
              end
            end
          end
          return maintainer
        end
      end

      def self.registered(app)
        app.helpers Helpers

        app.get '/login/?' do
          redirect '/'
        end

        app.post '/login/?' do
          env['warden'].authenticate!
          redirect '/'
        end

        app.post '/unauthenticated' do
          # report the failed login, so we can use fail2ban on the server
          logger = Logger.new('auth.log')
          logger.datetime_format = "%Y-%m-%d %H:%M:%S"
          logger.warn "Authentication failure for #{request.env['REMOTE_ADDR']}"
          logger.close

          view :login_unauthenticated
        end

        app.get '/logout/?' do
          env['warden'].logout
          redirect '/'
        end

        app.get '/login/forgot' do
          view :login_forgot
        end

        app.post '/login/forgot' do
          maintainer = maintainer_forgot(params[:username])
          if maintainer
            chars = ("a".."z").to_a + ("A".."Z").to_a + ("1".."9").to_a
            maintainer.token = Array.new(10, '').collect{chars[rand(chars.size)]}.join
            maintainer.token_stamp = Time.now.to_f
            maintainer.save

            # parameters used in the template
            params[:token_url] = Moka::Models::Configuration.get(:moka_url) +
                                 "/login/forgot/" + maintainer.username +
                                 "/" + maintainer.token
            params[:token_abort_url] = params[:token_url] + "/cancel"
            params[:token_expire] = (Time.now + 3600 * 2).to_s

            Pony.mail :to => maintainer.email,
                      :from => Moka::Models::Configuration.get(:noreply),
                      :subject => "Xfce Release Manager change password request",
                      :body => erb(:'email/login_forget')
          end

          env[:step] = "emailed"
          view :login_forgot
        end

        app.get '/login/forgot/:username/:token' do
          maintainer = maintainer_forgot(params[:username], params[:token])
          if maintainer
            env[:step] = "valid"
          else
            env[:step] = "invalid"
          end

          view :login_forgot
        end

        app.get '/login/forgot/:username/:token/cancel' do
          maintainer = Moka::Models::Maintainer.get(params[:username])
          if maintainer and maintainer.token.eql? params[:token]
            maintainer.token = nil
            maintainer.token_stamp = 0
            maintainer.save
          end

          env[:step] = "canceled"
          view :login_forgot
        end

        app.post '/login/forgot/:username/:token' do
          maintainer = maintainer_forgot(params[:username], params[:token])
          if maintainer
            if validate_password(params[:newpassword], params[:newpassword2])
              # update password
              maintainer.password = Digest::SHA1.hexdigest(params['newpassword'])
              maintainer.token = nil
              maintainer.token_stamp = 0
              maintainer.save

              env[:step] = "complete"
            else
              env[:step] = "valid"
            end
          else
            env[:step] = "invalid"
          end

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
            error_set(:message, 'All fields below are required')
            view :login_request
          elsif (params[:username] =~ /^[a-z]*$/).nil?
            error_set(:message, 'The username can only contain lowercaser letters')
            view :login_request
          elsif (params[:email] =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i).nil?
            error_set(:message, 'Please use a valid email address')
            view :login_request
          elsif not validate_password(params[:password], params[:password2])
            # error is set in function
            view :login_request
          elsif not Moka::Models::Maintainer.get(params[:username]).nil?
            error_set(:message, 'This username is already taken')
            view :login_request
          else
            @maintainer = Moka::Models::Maintainer.create(:username => params[:username])
            @maintainer.email = params[:email]
            @maintainer.realname = params[:realname]
            @maintainer.password = Digest::SHA1.hexdigest(params[:password])
            @maintainer.active = false
            @maintainer.save

            subject = "Xfce Release Manager Request: " + params[:username]
            body = erb(:'email/login_request')

            # mail all admins about the request
            recipients = Moka::Models::Maintainer.all()
            for recipient in recipients
              if recipient.is_admin
                Pony.mail :to => recipient.email,
                          :from => Moka::Models::Configuration.get(:noreply),
                          :subject => subject,
                          :body => body
              end
            end

            view :login_request_finished
          end
        end
      end
    end
  end
end
