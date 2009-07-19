#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'moka'

use Moka::Middleware::Identica do |identica|
  identica.username = 'username'
  identica.password = 'password'
  identica.group    = 'group'
end

use Moka::Middleware::Mailinglists do |mailer|
  mailer.lists = [ 'announce@someproject.org', 'another-list@someproject.org' ]
  
  mailer.project_subject do |release, message, sender|
    "#{release.project.name} #{release.version} released"
  end

  mailer.project_body do |release, message, sender| 
    ERB.new(File.read('project_release_mail.erb')).result(binding)
  end
end

Moka::Models::Configuration.load do |conf|
  conf.set :moka_url, 'https://moka.someproject.org'
  conf.set :archive_dir, '/var/www/download.someproject.org'
end

Moka::Models::Maintainer.load do
  [ Moka::Models::Maintainer.new('username', 'Real Name', 'SHA1 password', 'mail@someproject.org') ]
end

Moka::Models::Project.load do
  [ Moka::Models::Project.new('someproject', [ 'username' ], [ 'announce@someproject.org' ]) ]
end

Moka::Models::Mirror.load do
  [ Moka::Models::Mirror.new('http://download.someproject.org') ]
end

run Moka::Application
