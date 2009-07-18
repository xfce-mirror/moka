module Moka
  module Component
    module Collections
      def self.registered(app)
        app.get '/collection/:name/release/:release' do
          @collection = Collection.find_by_name(params[:name])
          @release = Collection::Release.new(@collection, params[:release])
          erb :collection_release
        end
        
        app.post '/collection/:name/release/:release' do
          @collection = Collection.find_by_name(params[:name])
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
    
          erb :collection_release
        end
        
        app.get '/collection/:name/release/:release/delete' do
          @collection = Collection.find_by_name(params[:name])
          erb :collection_delete
        end
        
       app. post '/collection/:name/release/:release/delete' do
          @collection = Collection.find_by_name(params[:name])
          @release = Collection::Release.new(@collection, params[:release])
          @release.delete
          redirect '/'
        end
        
        app.get '/collection/:name/new-release' do
          @collection = Collection.find_by_name(params[:name])
        end
      end
    end
  end
end
