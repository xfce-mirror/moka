require 'rubygems'
require 'sinatra'


directory = File.expand_path(File.dirname(__FILE__))

for n in ['archive', 'classification', 'collection', 'configuration', 'group', 'maintainer', 'project', 'role']
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

    set :public_folder, File.dirname(__FILE__) + '/../static'

    include Moka::Models

    register Moka::Helpers::General

    register Moka::Controllers::Announcements
    register Moka::Controllers::Authentication
    register Moka::Controllers::Projects
    register Moka::Controllers::Collections
    register Moka::Controllers::Maintainers

    authentication_initialize
  
    get '/' do
      if authentication_finished?
        view :index_login
      else
        view :index
      end
    end
  end
end
