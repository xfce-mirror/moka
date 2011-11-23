module Moka
  module Controllers
    module Projects
      include Moka::Models

      def self.registered(app)
        app.get '/project' do

          authentication_required

          view :project_list
        end

        app.post '/project' do

          authentication_required

          if params[:name] and not params[:name].empty?
            project = Moka::Models::Project.first_or_create(:name => params[:name].strip)

            classification = Classification.find_by_name(params[:classification])
            project.classify_as(classification) if classification

            project.save

            redirect "/project/#{params[:name]}"
          else
            view :project_list
          end
        end

        app.get '/project/:name' do
          @project = Project.get(params[:name])

          authentication_required(@project)

          view :project
        end

        app.post '/project/:name/information' do
          @project = Project.get(params[:name])

          authentication_required(@project)

          @project.website = params[:website]
          @project.longdesc = params[:longdesc]
          @project.shortdesc = params[:shortdesc]
          @project.owner = params[:owner]
          @project.save

          redirect "/project/#{params[:name]}"
        end

        app.post '/project/:name/classify' do
          @project = Project.get(params[:name])

          authentication_required

          classification = Classification.find_by_name(params[:classification])
          @project.classify_as(classification)

          redirect "/project/#{params[:name]}"
        end

        app.post '/project/:name/groups' do
          project = Project.get(params[:name])

          authentication_required

          project.groups.clear
          if params[:groups]
            for name in params[:groups].keys do
              group = Group.get(name)
              project.groups << group
            end
          end
          project.save

          redirect "/project/#{params[:name]}"
        end

        app.get '/project/:name/branch/:branch/release/:version/update' do
          @project = Project.get(params[:name])

          authentication_required(@project)

          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])
          view :project_release_update
        end

        app.post '/project/:name/branch/:branch/release/:version/update' do
          @project = Project.get(params[:name])

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
          @project = Project.get(params[:name])

          authentication_required(@project)

          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])

          view :project_release_delete
        end

        app.post '/project/:name/branch/:branch/release/:version/delete' do
          @project = Project.get(params[:name])

          authentication_required(@project)

          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])

          if env['feeds']
            env['feeds'].delete_release(@release)
          end

          @release.delete

          redirect "/project/#{@project.name}"
        end

        app.get '/project/:name/new-release' do
          @project = Project.get(params[:name])

          authentication_required(@project)

          view :project_new_release
        end

        app.get '/project/:name/new-release/tarball' do
          @project = Project.get(params[:name])

          authentication_required(@project)

          view :project_new_release_tarball
        end

        app.post '/project/:name/new-release/tarball' do
          @project = Project.get(params[:name])

          authentication_required(@project)

          error_set(:tarball, 'No file specified.') if params[:tarball].nil?

          unless error_set?
            unless params[:tarball][:filename] =~ @project.tarball_upload_pattern
              error_set(:tarball, "Tarball has to match the pattern<br/><tt>#{@project.tarball_upload_pattern.source}</tt>.")
            end
          end

          unless error_set?
            checksum = Digest::SHA1.hexdigest(params[:tarball][:tempfile].read())
            if params[:checksum] != checksum
              error_set(:checksum, 'Uploaded file corrupted. ' \
                        'Please verify the checksum is correct and try again .')
            end
          end

          @release = @project.release_from_tarball(params[:tarball][:filename])
          @branch = @release.branch

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
            redirect "/project/#{params[:name]}/branch/#{@branch.name}/new-release/#{@release.version}/announcement"
          else
            view :project_new_release_tarball
          end
        end

        app.get '/project/:name/branch/:branch/new-release/:version/announcement' do
          @project = Project.get(params[:name])

          authentication_required(@project)

          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])

          view :project_branch_new_release_announcement
        end

        app.post '/project/:name/branch/:branch/new-release/:version/announcement' do
          @project = Project.get(params[:name])

          authentication_required(@project)

          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])

          if env['feeds']
            if env['identica'] and params[:identica]
              url = env['feeds'].get_project_feed_url(@project)

              if env['identica'].group.nil?
                @announcement_status = "#{@project.name} #{@release.version} released: #{url}"
              else
                @announcement_status = "#{@project.name} #{@release.version} released: #{url} !#{env['identica'].group}"
              end
            end

            if params[:feeds]
              # TODO
            end
          end

          if env['mailinglists'] and params[:mailinglists]
            @announcement_subject = env['mailinglists'].render_subject(@release, params[:message], authentication_user)
            @announcement_body = env['mailinglists'].render_body(@release, params[:message], authentication_user)
          end

          view :project_branch_new_release_confirm
        end

        app.post '/project/:name/branch/:branch/new-release/:version/confirm' do
          @project = Project.get(params[:name])

          authentication_required(@project)

          @branch = Project::Branch.new(@project, params[:branch])
          @release = Project::Release.new(@project, @branch, params[:version])

          unless error_set?
            if env['feeds'] and params[:feeds]
              env['feeds'].announce_release(@release, params[:message], authentication_user)
            end

            if env['identica'] and params[:identica]
              url = env['feeds'].get_project_feed_url(@project)

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
        end

      end
    end
  end
end
