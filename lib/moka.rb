require 'rubygems'
require 'sinatra'
require 'sass'

directory = File.expand_path(File.dirname(__FILE__))

models = ['configuration', 'classification', 'group', 'role', 'maintainer', 'collection', 'project', 'archive']
for model in models
  require File.join(directory, 'models', model)
end

require File.join(directory, 'helpers', 'general')
require File.join(directory, 'helpers', 'gitolite')

helpers = ['announcements', 'authentication', 'collections', 'projects', 'maintainers']
for helper in helpers
  require File.join(directory, 'controllers', helper)
end

middlewares = ['feeds', 'identica', 'mailinglists']
for middleware in middlewares
  require File.join(directory, 'middleware', middleware)
end

module Moka
  class Application < Sinatra::Base

    include Moka::Models

    register Moka::Helpers::General

    register Moka::Controllers::Announcements
    register Moka::Controllers::Authentication
    register Moka::Controllers::Projects
    register Moka::Controllers::Collections
    register Moka::Controllers::Maintainers

    authentication_initialize
  
    get '/stylesheet.css' do
      content_type 'text/css', :charset => 'utf-8'

      directory = File.join(File.expand_path(File.dirname(__FILE__)), 'views')
  
      template = File.read(File.join(directory, 'stylesheet.sass'))
      engine = Sass::Engine.new(template)
      engine.render
    end
  
    get '/' do
      if authentication_finished?
        view :index_login
      else
        view :index
      end
    end
  end
end
