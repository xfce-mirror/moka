require 'rubygems'
require 'sinatra'
require 'pp'

module Moka
  class CGit
    include Moka::Models

    def run(repofile, gitpath, prepend_files = nil)

      conf = "# This file is generated by Moka\n\n"
      public = Moka::Models::Group.get('public')

      for classification in Moka::Models::Classification.find_all.sort

        sect = ""

        for name in classification.project_names.sort

            path = File.join(gitpath, classification.name, name) + ".git"
            next unless File.directory?(path)

            project = Moka::Models::Project.get(name)
            next if project == nil

            # only show public projects
            next unless project.groups.include?(public)

            sect << "repo.url=#{classification.name}/#{project.name}\n"
            sect << "repo.name=#{project.name}\n"
            sect << "repo.path=#{path}\n"
            sect << "repo.desc=#{project.shortdesc}\n"
            sect << "repo.owner=#{project.owner}\n\n"
        end

        if not sect.empty?
          conf << "section=#{classification.name}\n\n"
          conf << sect
        end
      end

      # write contents to file
      cfile = File.new(repofile, "w+")
      begin
        cfile.flock(File::LOCK_SH)
        cfile.puts conf
      ensure
        cfile.flock(File::LOCK_UN)
      end
      cfile.close
    end
  end
end
