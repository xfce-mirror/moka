module Moka
  module Controllers
    module Maintainers
      include Moka::Models

      def self.registered(app)
        app.get '/maintainer/:username' do
          @maintainer = Maintainer.find_by_username(params[:username])

          authentication_required(@maintainer)

          view :maintainer
        end
        
        app.post '/maintainer/:username' do
          @maintainer = Maintainer.find_by_username(params[:username])

          authentication_required(@maintainer)

	  @maintainer.email = params[:email]
	  @maintainer.save
          
	  view :maintainer
        end

      end
    end
  end
end
