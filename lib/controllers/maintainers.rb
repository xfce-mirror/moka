module Moka
  module Controllers
    module Maintainers
      include Moka::Models

      def self.registered(app)
        app.get '/maintainer/profile/:username' do
          @maintainer = Maintainer.find_by_username(params[:username])

          authentication_required(@maintainer)

          view :maintainer_profile
        end

        app.get '/maintainer' do

          authentication_required

          view :maintainer
        end

        app.post '/maintainer/profile/:username' do
          @maintainer = Maintainer.find_by_username(params[:username])

          authentication_required(@maintainer)

          # validate the password against the authenticated user
          encrypted_password = Digest::SHA1.hexdigest(params[:password])
          if Moka::Models::Maintainer.use_http_auth? or authentication_user.password == encrypted_password
            if not params[:new_password].empty?
              if not params[:new_password].eql? params[:new_password2]
                error_set(:newpassword, 'The two passwords you entered did not match.')
              elsif params[:new_password].length < 6
                error_set(:newpassword, 'The password must be at least 6 characters long.')
              else
                encrypted_password = Digest::SHA1.hexdigest(params[:new_password])
                @maintainer.password = encrypted_password
              end
            end

            # cleanup the pubkeys
            pubkeys = []
            params[:pubkeys].split("\n").each do |key|
              key = key.strip
              pubkeys.push(key) if not key.empty?
            end

            @maintainer.email = params[:email]
            @maintainer.realname = params[:realname]
            @maintainer.pubkeys = pubkeys
            @maintainer.save

            error_set(:succeed, 'The changes to your profile have been saved.')
          else
            if authentication_user.username == @maintainer.username
              error_set(:password, 'You did not enter your old password correctly.')
            else
              error_set(:password, 'You did not enter your OWN password correctly.')
            end
          end

          view :maintainer_profile
        end
      end
    end
  end
end
