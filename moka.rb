require 'rubygems'
require 'sass'
require 'warden'
require 'lib/archive'
require 'lib/classification'
require 'lib/collection'
require 'lib/configuration'
require 'lib/maintainer'
require 'lib/mailinglist'
require 'lib/mirror'
require 'lib/project'
require 'components/auth'
require 'components/general'
require 'components/identica'
require 'components/projects'
require 'components/collections'

class Moka::Application < Sinatra::Base

  helpers Moka::Component::General::Helpers
  helpers Moka::Component::Auth::Helpers
  helpers Moka::Component::Identica::Helpers

  register Moka::Component::General
  register Moka::Component::Auth
  register Moka::Component::Identica
  register Moka::Component::Projects
  register Moka::Component::Collections

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
