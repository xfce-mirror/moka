module Xfce
  module ReleaseManager
    module App
      module Collection
        
        get '/collection/:name/release/:release' do
          @collection = Collection.find_by_name(params[:name])
          @release = Release.new(params[:release])
          erb :collection_release
        end
        
        post '/collection/:name/release/:release' do
          @collection = Collection.find_by_name(params[:name])
          @release = Release.new(params[:release])
    
          for project in Project.find_all
           next unless params.has_key?(project.name)
           branch, version = params[project.name]['version'].split(/:/)
    
           if version.nil?
             @collection.remove_project(@release, project)
           else
             release = Release.new(version)
             @collection.add_project(@release, project, branch, release)
           end
          end
    
          erb :collection_release
        end
        
        get '/collection/:name/release/:release/delete' do
          @collection = Collection.find_by_name(params[:name])
          erb :collection_delete
        end
        
        post '/collection/:name/release/:release/delete' do
          @collection = Collection.find_by_name(params[:name])
          "Deleting release #{params[:release]} of collection #{@collection.name}"
        end
        
        get '/collection/:name/new-release' do
          @collection = Collection.find_by_name(params[:name])
        end
      end
    end
  end
end
