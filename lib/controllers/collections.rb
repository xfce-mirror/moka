module Moka
  module Controllers
    module Collections
      include Moka::Models

      def self.registered(app)
        app.get '/collection/:name/release/:release' do
          @collection = Collection.find_by_name(params[:name])

          authentication_required(@collection)

          @release = Collection::Release.new(@collection, params[:release])
          view :collection_release
        end
        
        app.post '/collection/:name/release/:release' do
          @collection = Collection.find_by_name(params[:name])

          authentication_required(@collection)

          @release = Collection::Release.new(@collection, params[:release])
    
          for project in Project.find_all
           next unless params[:version].has_key?(project.name)
           branch_name, version = params[:version][project.name].split(/:/)

           project_release = @release.included_project_release(project)
           @release.remove_project_release(project_release) unless project_release.nil?

           unless version.nil?
             branch = Project::Branch.new(project, branch_name)
             project_release = Project::Release.new(project, branch, version)
             @release.add_project_release(project_release)
           end
          end

          @release.update
    
          redirect '/'
        end
        
        app.get '/collection/:name/release/:release/delete' do
          @collection = Collection.find_by_name(params[:name])

          authentication_required(@collection)

          view :collection_delete
        end
        
       app. post '/collection/:name/release/:release/delete' do
          @collection = Collection.find_by_name(params[:name])

          authentication_required(@collection)

          @release = Collection::Release.new(@collection, params[:release])
          @release.delete
          redirect '/'
        end
        
        app.get '/collection/:name/new-release' do
          @collection = Collection.find_by_name(params[:name])

          authentication_required(@collection)

          view :collection_new_release
        end

        app.post '/collection/:name/new-release' do
          @collection = Collection.find_by_name(params[:name])

          authentication_required(@collection)

          @release = Collection::Release.new(@collection, params[:version])

          error_set(:version, 'Version may not be empty.') if params[:version].empty?

          unless error_set? 
            pattern = Regexp.new(Configuration.get(:collection_release_pattern))
            unless params[:version] =~ pattern
              error_set(:version, "Version has to match the pattern<br /><tt>#{pattern.source}</tt>")
            end
          end

          unless error_set?
            if @collection.releases.include?(@release)
              error_set(:version, 'Version already exists.') 
            end
          end

          unless error_set?
            for project_name, project_version in params[:project_version]
              next if project_version == 'nil'

              project = Project.find_by_name(project_name)

              project_release = project.releases.find do |prelease|
                prelease.version == project_version
              end

              @release.add_project_release(project_release)
            end

            if env['feeds']
              env['feeds'].announce_release(@release, params[:message], authentication_user)
            end
            
            if env['identica'] and params[:identica]
	      url = env['feeds'].get_collection_feed_url(@collection)

              if env['identica'].group.nil?
                status = "#{@collection.display_name} #{@release.version} released: #{url}"
              else
                status = "#{@collection.display_name} #{@release.version} released: #{url} !#{env['identica'].group}"
              end

              env['identica'].post(status)
            end
            
            if env['mailinglists'] and params[:mailinglists]
              env['mailinglists'].announce_release(@release, params[:message],
                                                   authentication_user, 
                                                   params[:mailinglists].keys)
            end

            redirect '/'
          end

          view :collection_new_release
        end
      end
    end
  end
end
