require 'rubygems'
require 'sass'
require 'warden'
require 'lib/archive'
require 'lib/classification'
require 'lib/configuration'
require 'lib/maintainer'
require 'lib/mailinglist'
require 'lib/mirror'
require 'lib/project'
require 'components/auth'
require 'components/general'
require 'components/identica'
require 'components/projects'

class Moka < Sinatra::Base

  helpers Sinatra::Component::General::Helpers
  helpers Sinatra::Component::Auth::Helpers
  helpers Sinatra::Component::Identica::Helpers

  register Sinatra::Component::General
  register Sinatra::Component::Auth
  register Sinatra::Component::Identica
  register Sinatra::Component::Projects

  initialize_authentication
  initialize_identica

  before do 
    env[:error] = {}
  end

  get '/stylesheet.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :stylesheet
  end

  get '/' do
    if env['warden'].authenticated?
      erb :manage_releases
    else
      erb :index
    end
  end

end
