require 'rubygems'
require 'sinatra'
require 'sass'

directory = File.expand_path(File.dirname(__FILE__))

for n in ['archive', 'autoindex', 'classification', 'collection', 'configuration', 'group', 'maintainer', 'project', 'role']
  require File.join(directory, 'models', n)
end

for n in ['cgit', 'general', 'gitolite']
  require File.join(directory, 'helpers', n)
end

for n in ['announcements', 'authentication', 'collections', 'projects', 'maintainers']
  require File.join(directory, 'controllers', n)
end

for n in ['feeds', 'identica', 'mailinglists']
  require File.join(directory, 'middleware', n)
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
