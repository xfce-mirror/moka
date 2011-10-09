#!/usr/bin/env ruby

require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'moka'

# global configuration
Moka::Models::Configuration.load do |conf|
  conf.set :moka_url, 'http://localhost:9292'
  conf.set :archive_dir, '/home/nick/websites/archive.xfce.org/'
  conf.set :mirror, 'http://archive.xfce.org/'
  conf.set :collection_release_pattern, /^([0-9]).([0-9]+)(pre[0-9])?$/
  conf.set :noreply, 'noreply@xfce.org'
end

# Connect to the database
directory = File.expand_path(File.dirname(__FILE__))
db = File.join(directory, '../examples/xfce/example.db')

#DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite://' + db)

gitolitedir = '/tmp/gitolitetest'

keydir = File.join(gitolitedir, "keydir")
File.makedirs(keydir) unless File.directory?(keydir)

confdir = File.join(gitolitedir, "conf")
File.makedirs(confdir) unless File.directory?(confdir)

# project array
projects = Hash.new

for maintainer in Moka::Models::Maintainer.all(:active => true).sort

  # update ssh key of this user
  if maintainer.pubkeys and not maintainer.pubkeys.empty?
    filename = File.join(keydir, maintainer.username + ".pub")
    file = File.new(filename, "w+")

    if file
      begin
        file.flock(File::LOCK_SH)
        file.puts maintainer.pubkeys
      ensure
        file.flock(File::LOCK_UN)
      end
      file.close
    else
      puts "Unable to open file " + filename
    end
  end

  # store the projects this maintainer handles
  for project in maintainer.projects
    if not projects[project.name]
      projects[project.name ] = Array.new
    end
    projects[project.name] << maintainer.username
  end
end


repo_rules = ""

# build the gitolite config file
for classification in Moka::Models::Classification.find_all.sort

  for project in classification.project_names.sort

    repo_rules << "repo " + classification.name + "/" + project + "\n"

    if projects[project]
      repo_rules << "\tRW ="
      for username in projects[project].sort
        repo_rules << " " + username
      end
      repo_rules << "\n"
    end
  repo_rules << "\n"
  end
end

# write config file
cfile = File.new(File.join(confdir, "gitolite.conf"), "w+")
begin
  cfile.flock(File::LOCK_SH)
  cfile.puts repo_rules
ensure
  cfile.flock(File::LOCK_UN)
end
cfile.close
