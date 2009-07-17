require 'rubygems'
require 'sass'
require 'warden'
require 'lib/archive'
require 'lib/classification'
require 'lib/maintainer'
require 'lib/mailinglist'
require 'lib/project'
require 'components/auth'
require 'components/general'
require 'components/projects'

class Moka < Sinatra::Base

  helpers Sinatra::Component::General::Helpers
  helpers Sinatra::Component::Auth::Helpers

  register Sinatra::Component::Auth
  register Sinatra::Component::Projects

  initialize_authentication

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

  def self.archive_dir=(dir)
    Archive.instance.root_dir = dir
  end

  def self.excluded_classifications=(list)
    Archive.instance.excluded_classifications = list
  end

end
