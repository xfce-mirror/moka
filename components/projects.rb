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

          if params[:tarball].nil?
            env[:error][:tarball] = 'No file specified.'
          else
            if params[:tarball][:filename] != @release.tarball_basename
              env[:error][:tarball] = "Wrong filename. <tt>#{@release.tarball_basename}</tt> required."
            else
              tempfile_checksum = Digest::SHA1.hexdigest(params[:tarball][:tempfile].read())
              if params[:checksum] != tempfile_checksum
                env[:error][:checksum] = 'Uploaded file corrupted. Please verify the checksum is correct and try again.'
              else
                @release.add_tarball(params[:tarball][:tempfile])
                redirect "/project/#{params[:name]}"
              end
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
          @branch = params[:branch]
          erb :project_new_release
        end

        app.post '/project/:name/branch/:branch/new-release' do
          @project = Project.find_by_name(params[:name])
          @branch = Project::Branch.new(@project, params[:branch])

          if params[:tarball].nil?
            env[:error][:tarball] = 'No file specified.'
          else
            tempfile_checksum = Digest::SHA1.hexdigest(params[:tarball][:tempfile].read())
            if params[:checksum] != tempfile_checksum
              env[:error][:checksum] = 'Uploaded file corrupted. Please verify the checksum is correct and try again .'
            else
              @branch.add_tarball(params[:tarball][:tempfile], params[:tarball][:filename])
              redirect "/project/#{@project.name}"
            end
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
