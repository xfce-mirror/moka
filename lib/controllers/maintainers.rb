module Moka
  module Controllers
    module Maintainers
      include Moka::Models

      def self.registered(app)
        app.get '/maintainer' do

          authentication_required

          view :maintainer
        end

        app.post '/maintainer' do

          authentication_required

          unless params[:from].empty? or params[:subject].empty? or params[:body].empty?
            for maintainer in Maintainer.all(:active => true)
              next if maintainer.email.empty?

              body = params[:body]
              body.gsub!('<realname>', maintainer.realname)
              body.gsub!('<username>', maintainer.username)

              Pony.mail :to => maintainer.email,
                        :from => params[:from],
                        :subject => params[:subject],
                        :body => body
            end
          end

          view :maintainer
        end

        app.get '/maintainer/:name' do
          @maintainer = Maintainer.get(params[:name])

          authentication_required(@maintainer)

          view :maintainer_profile
        end

        app.post '/maintainer/:username' do
          @maintainer = Maintainer.get(params[:username])

          authentication_required(@maintainer)

          # validate the password against the authenticated user
          encrypted_password = Digest::SHA1.hexdigest(params[:password])
          if authentication_user.password.eql? encrypted_password
            if params[:newpassword] and
               not params[:newpassword].empty? and
               validate_password(params[:newpassword], params[:newpassword2])
              encrypted_password = Digest::SHA1.hexdigest(params[:newpassword])
              @maintainer.password = encrypted_password
            end

            # put lines in an array and clean it up
            pubkeys_arr = []
            params[:pubkeys].split("\n").each do |key|
              key = key.strip
              pubkeys_arr.push(key) if not key.empty? and key.start_with? "ssh-"
            end
            pubkeys = pubkeys_arr.join("\n")

            if not @maintainer.email.to_s.eql? params[:email].to_s
              # send mail to old address
              Pony.mail :to => @maintainer.email,
                        :from => Moka::Models::Configuration.get(:noreply),
                        :subject => 'Release Manager Profile Change: E-mail',
                        :body => erb(:'email/maintainer_change_email')

              @maintainer.email = params[:email]
            end

            if not @maintainer.pubkeys.to_s.eql? pubkeys.to_s
              # send mail to new address
              Pony.mail :to => @maintainer.email,
                        :from => Moka::Models::Configuration.get(:noreply),
                        :subject => 'Release Manager Profile Change: SSH',
                        :body => erb(:'email/maintainer_change_ssh')

              @maintainer.pubkeys = pubkeys
            end

            @maintainer.realname = params[:realname]
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

        app.post '/maintainer/:username/activate' do
          authentication_required

          maintainer = Maintainer.get(params[:username])
          if maintainer
            maintainer.active = !maintainer.active
            maintainer.save

            if maintainer.active
              Pony.mail :to => @maintainer.email,
                        :from => Moka::Models::Configuration.get(:noreply),
                        :subject => 'Release Manager Account Activated',
                        :body => erb(:'email/maintainer_activated')
            end
          end

          redirect "/maintainer/#{params[:username]}"
        end

        app.post '/maintainer/:name/delete' do
          authentication_required

          maintainer = Maintainer.get(params[:name])
          maintainer.destroy if maintainer and not maintainer.active

          view :maintainer
        end

        app.post '/maintainer/:name/permissions' do
          authentication_required

          maintainer = Maintainer.get(params[:name])
          maintainer.roles.clear
          if params[:roles]
            for name in params[:roles].keys do
              role = Role.get(name)
              maintainer.roles << role
            end
          end

          maintainer.collections.clear
          if params[:collections]
            for name in params[:collections].keys do
              collection = Collection.get(name)
              maintainer.collections << collection
            end
          end

          maintainer.projects.clear
          if params[:projects]
            for name in params[:projects].keys do
              project = Project.get(name)
              maintainer.projects << project
            end
          end

          maintainer.save

          redirect "/maintainer/#{maintainer.username}"
        end
      end
    end
  end
end
