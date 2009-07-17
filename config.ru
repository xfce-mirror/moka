#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'moka'

disable :run
enable :static, :session, :methodoverride, :reload
set :environment, :development

Moka.archive_dir = File.dirname(__FILE__) + '/archive'
Moka.excluded_classifications = [ 'xfce-releases' ]

run Moka
