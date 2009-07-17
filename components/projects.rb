module Sinatra
  module Component
    module Projects
      def self.registered(app)
        app.get '/project/:name' do
          requires_authentication

          @project = Project.find_by_name(params[:name])
          erb :project
        end
        
        app.post '/project/:name/classify' do
          project = Project.find_by_name(params[:name])
          classification = Classification.find_by_name(params[:classification])

          project.classify_as(classification)

          redirect "/project/#{params[:name]}"
        end

        app.get '/project/:name/branch/:branch/release/:version/update' do
          @project = Project.find_by_name(params[:name])
          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])
          erb :project_release_update
        end

        app.post '/project/:name/branch/:branch/release/:version/update' do
          @project = Project.find_by_name(params[:name])
          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])

          error_set(:tarball, 'No file specified.') if params[:tarball].nil?
            
          unless error_set?
            if params[:tarball][:filename] != @release.tarball_basename
              error_set(:tarball, "Wrong filename. <tt>#{@release.tarball_basename}</tt> required.")
            end
          end

          unless error_set?
            checksum = Digest::SHA1.hexdigest(params[:tarball][:tempfile].read())
            if params[:checksum] != checksum
              error_set(:checksum, 'Uploaded file corrupted. ' \
                        'Please verify the checksum is correct and try again.')
            end
          end

          unless error_set?
            begin
              @release.add_tarball(params[:tarball][:tempfile])
              redirect "/project/#{params[:name]}"
            rescue Exception => error
              error_set(:tarball, "Failed to upload tarball: #{error.message}")
            end
          end

          erb :project_release_update
        end

        app.get '/project/:name/branch/:branch/release/:version/delete' do
          @project = Project.find_by_name(params[:name])
          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])
          erb :project_release_delete
        end

        app.post '/project/:name/branch/:branch/release/:version/delete' do
          @project = Project.find_by_name(params[:name])
          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])
          @release.delete
          redirect "/project/#{@project.name}"
        end

        app.get '/project/:name/branch/:branch/new-release' do
          @project = Project.find_by_name(params[:name])
          @branch = Project::Branch.new(@project, params[:branch])
          erb :project_new_release
        end

        app.post '/project/:name/branch/:branch/new-release' do
          @project = Project.find_by_name(params[:name])
          @branch = Project::Branch.new(@project, params[:branch])

          error_set(:tarball, 'No file specified.') if params[:tarball].nil?

          unless error_set?
            unless params[:tarball][:filename] =~ @project.tarball_pattern
              error_set(:tarball, "Tarball has to match the pattern <tt>#{@project.tarball_pattern.source}</tt>.")
            end
          end

          unless error_set?
            checksum = Digest::SHA1.hexdigest(params[:tarball][:tempfile].read())
            if params[:checksum] != checksum
              error_set(:checksum, 'Uploaded file corrupted. ' \
                        'Please verify the checksum is correct and try again .')
            end
          end

          @release = @branch.release_from_tarball(params[:tarball][:filename])

          unless error_set?
            if @branch.has_release?(@release)
              error_set(:tarball, "Release tarball already exists. " \
                         "You can use <a href=\"/project/#{@project.name}/branch/#{@branch.name}/release/#{@release.version}/update\">this page</a> to update the release.")
            end
          end

          unless error_set?
            begin
              #@branch.add_tarball(params[:tarball][:tempfile], params[:tarball][:filename])
            rescue Exception => error
              error_set(:tarball, "Failed to upload the tarball: #{error.message}.")
            end
          end

          unless error_set?
            unless params[:identica].nil?
              identica_announce_release(@release, "https://release.xfce.org/feed/project/#{@project.name}")
            end
            
            mailinglists = params[:mailinglists].keys.collect do |email|
              Mailinglist.find_by_email(email)
            end

            for mailinglist in mailinglists
              mailinglist.announce_release(env['warden'].user, @release, params[:greeting], params[:message])
            end
            
           # redirect "/project/#{@project.name}"
          end

          erb :project_new_release
        end

        app.get '/project/:name/new-release' do
          @project = Project.find_by_name(params[:name])
          erb :project_new_branch
        end

        app.post '/project/:name/new-release' do
          redirect "/project/#{params[:name]}/branch/#{params[:branch]}/new-release"
        end
      end
    end
  end
end
