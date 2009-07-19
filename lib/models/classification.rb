module Moka
  module Models
    class Classification
    
      attr_accessor :name
      attr_accessor :directory
      attr_accessor :project_names
    
      def initialize(name, directory)
        @name = name
        @directory = directory
        @project_names = []
      end
    
      def self.find_all
        Archive.instance.classifications
      end
    
      def self.find_by_name(name)
        find_all.find do |classification|
          classification.name == name
        end
      end
    
      def self.find_by_project(project)
        find_all.find do |classification|
          classification.project_names.include?(project.name)
        end
      end
    
    end
  end
end
