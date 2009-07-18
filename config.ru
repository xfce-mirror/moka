#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'moka'

disable :run
enable :static, :session, :methodoverride, :reload
set :environment, :development

run Moka::Application
