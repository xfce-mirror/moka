#!/usr/bin/env ruby

require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'digest/sha1'

require '../../lib/moka'

directory = File.expand_path(File.dirname(__FILE__))
db = File.join(directory, 'example.db')

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite://' + db)

use Moka::Middleware::Identica do |identica|
  identica.username = 'username'
  identica.password = 'password'
  identica.group    = 'group'
end

# global configuration
Moka::Models::Configuration.load do |conf|
  conf.set :moka_url, 'https://releases.xfce.org'
  conf.set :archive_dir, '/home/nick/websites/archive.xfce.org/'
  conf.set :archive_url, 'http://archive.xfce.org'
  conf.set :collection_release_pattern, /^([0-9]).([0-9]+)(pre[0-9])?$/
end

# Uncheck for production environment
DataMapper.auto_migrate!

# create dummy roles
admin = Moka::Models::Role.first_or_create(:name => 'admin')
admin.save

# create dummy user
user = Moka::Models::Maintainer.first_or_create(
  { :username => 'nick' },
  { :realname => 'Nick Schermer',
    :password => Digest::SHA1.hexdigest('test'),
    :email => 'nick@xfce.org' }
)
user.roles << admin
user.save
user = Moka::Models::Maintainer.first_or_create(
  { :username => 'jannis' },
  { :realname => 'Jannis Pohlmann',
    :password => Digest::SHA1.hexdigest('test'),
    :email => 'jannis@xfce.org' }
)
user.save
user = Moka::Models::Maintainer.first_or_create(
  { :username => 'jeromeg' },
  { :realname => 'Jérôme Guelfuccin',
    :password => Digest::SHA1.hexdigest('test'),
    :email => 'jeromeg@xfce.org' }
)
user.save

project = Moka::Models::Project.first_or_create(
  { :name =>        'xfce4-panel' },
  { :website =>     'http://www.xfce.org',
    :description => 'Xfce\'s Panel' }
)
project.maintainers << user
project.save

# create dummy classification
collection = Moka::Models::Collection.first_or_create(
  { :name => 'xfce' },
  { :display_name => 'Xfce',
    :website => 'http://www.xfce.org' }
)
collection.maintainers << user
collection.save

run Moka::Application
