require 'rubygems'

require 'json'
require 'json/add/core'

gem 'sinatra', '0.9.2'
require 'sinatra'

gem 'haml', '2.2.1'
require 'sass'

directory = File.expand_path(File.dirname(__FILE__))

require File.join(directory, 'models', 'configuration')
require File.join(directory, 'models', 'classification')
require File.join(directory, 'models', 'collection')
require File.join(directory, 'models', 'maintainer')
require File.join(directory, 'models', 'mirror')
require File.join(directory, 'models', 'project')
require File.join(directory, 'models', 'archive')

require File.join(directory, 'helpers', 'general')

require File.join(directory, 'controllers', 'authentication')
require File.join(directory, 'controllers', 'collections')
require File.join(directory, 'controllers', 'projects')
require File.join(directory, 'controllers', 'maintainers')

require File.join(directory, 'middleware', 'feeds')
require File.join(directory, 'middleware', 'identica')
require File.join(directory, 'middleware', 'mailinglists')

module Moka
  class Application < Sinatra::Base

    include Moka::Models

    register Moka::Helpers::General

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
        view :manage_releases
      else
        view :index
      end
    end
  
  end
end
