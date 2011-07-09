module Moka
  module Controllers
    module Maintainers
      include Moka::Models

      def self.registered(app)
        app.get '/maintainer/:name' do
          @maintainer = Maintainer.get(params[:name])

          authentication_required(@maintainer)

          view :maintainer_profile
        end

        app.get '/maintainer' do

          authentication_required

          view :maintainer
        end

        app.post '/maintainer/:id' do
          @maintainer = Maintainer.get(params[:name])

          authentication_required(@maintainer)

          # validate the password against the authenticated user
          encrypted_password = Digest::SHA1.hexdigest(params[:password])
          if authentication_user.password == encrypted_password
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

            # put lines in an array and clean it up
            pubkeys = []
            params[:pubkeys].split("\n").each do |key|
              key = key.strip
              pubkeys.push(key) if not key.empty?
            end

            @maintainer.email = params[:email]
            @maintainer.realname = params[:realname]
            @maintainer.pubkeys = pubkeys.join("\n")
            @maintainer.save

            error_set(:succeed, 'The changes to your profile have been saved.')
          else
            if authentication_user.name == @maintainer.name
              error_set(:password, 'You did not enter your old password correctly.')
            else
              error_set(:password, 'You did not enter your OWN password correctly.')
            end
          end

          view :maintainer_profile
        end

        app.post '/maintainer/:name/permissions' do
          @maintainer = Maintainer.get(params[:name])

          authentication_required

          @maintainer.roles.clear
          if params[:roles]
            for name in params[:roles].keys do
              role = Role.get(name)
              @maintainer.roles << role
            end
          end

          @maintainer.collections.clear
          if params[:collections]
            for name in params[:collections].keys do
              collection = Collection.get(name)
              @maintainer.collections << collection
            end
          end

          @maintainer.projects.clear
          if params[:projects]
            for name in params[:projects].keys do
              project = Project.get(name)
              @maintainer.projects << project
            end
          end

          @maintainer.save

          redirect "/maintainer/#{@maintainer.username}"
        end
      end
    end
  end
end
