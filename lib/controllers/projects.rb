module Moka
  module Controllers
    module Projects
      include Moka::Models

      def self.registered(app)
        app.get '/project/:name' do
          @project = Project.find_by_name(params[:name])

          authentication_required(@project)

          view :project
        end
        
        app.post '/project/:name/classify' do
          @project = Project.find_by_name(params[:name])
          
          authentication_required(@project)

          classification = Classification.find_by_name(params[:classification])
          @project.classify_as(classification)

          redirect "/project/#{params[:name]}"
        end

        app.get '/project/:name/branch/:branch/release/:version/update' do
          @project = Project.find_by_name(params[:name])
          
          authentication_required(@project)

          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])
          view :project_release_update
        end

        app.post '/project/:name/branch/:branch/release/:version/update' do
          @project = Project.find_by_name(params[:name])
          
          authentication_required(@project)

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

          view :project_release_update
        end

        app.get '/project/:name/branch/:branch/release/:version/delete' do
          @project = Project.find_by_name(params[:name])
          
          authentication_required(@project)

          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])
          view :project_release_delete
        end

        app.post '/project/:name/branch/:branch/release/:version/delete' do
          @project = Project.find_by_name(params[:name])

          authentication_required(@project)

          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])
          @release.delete
          redirect "/project/#{@project.name}"
        end

        app.get '/project/:name/branch/:branch/new-release' do
          @project = Project.find_by_name(params[:name])

          authentication_required(@project)

          @branch = Project::Branch.new(@project, params[:branch])
          view :project_branch_new_release
        end

        app.post '/project/:name/branch/:branch/new-release' do
          @project = Project.find_by_name(params[:name])
          
          authentication_required(@project)

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
              @branch.add_tarball(params[:tarball][:tempfile], params[:tarball][:filename])
            rescue Exception => error
              error_set(:tarball, "Failed to upload the tarball: #{error.message}.")
            end
          end

          unless error_set?
            if env['identica'] and params[:identica]
              url = URI.join(Configuration.get(:moka_url), 'feed', 'project', @project.name).to_s

              if env['identica'].group.nil?
                status = "#{@project.name} #{@release.version} released: #{url}"
              else
                status = "#{@project.name} #{@release.version} released: #{url} !#{env['identica'].group}"
              end

              env['identica'].post(status)
            end
            
            if env['mailinglists'] and params[:mailinglists]
              env['mailinglists'].announce_release(@release, params[:message],
                                                   authentication_user, 
                                                   params[:mailinglists].keys)
            end
            
            redirect "/project/#{@project.name}"
          end

          view :project_branch_new_release
        end

        app.get '/project/:name/new-release' do
          @project = Project.find_by_name(params[:name])
          
          authentication_required(@project)

          view :project_new_release
        end

        app.post '/project/:name/new-release' do
          @project = Project.find_by_name(params[:name])
          
          authentication_required(@project)

          branch = if params[:branch] == 'nil' then params[:custom] else params[:branch] end
          redirect "/project/#{params[:name]}/branch/#{branch}/new-release"
        end
      end
    end
  end
end
