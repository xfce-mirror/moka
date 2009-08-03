module Moka
  module Models
    class Collection
    
      class Release
    
        attr :collection
        attr :version
    
        def initialize(collection, version)
          @collection = collection
          @version = version
        end
    
        def ==(other)
          other.is_a?(self.class) \
            and other.collection == collection \
            and other.version == version
        end
    
        def <=>(other)
          return 0 unless other.is_a?(self.class)
          return 1 if other.version.index(version) == 0
          return -1 if version.index(other.version) == 0
          version <=> other.version
        end
    
        def add_project_release(release)
          Archive.instance.collection_release_add_project_release(self, release)
        end
        
        def remove_project_release(release)
          Archive.instance.collection_release_remove_project_release(self, release)
        end

        def project_releases
          releases = []
          for project in Project.find_all
            release = included_project_release(project)
            releases << release unless release.nil?
          end
          releases
        end
    
        def included_project_release(project)
          project.releases.find do |release| 
            Archive.instance.collection_release_project_release_included?(self, release)
          end
        end
    
        def delete
          Archive.instance.collection_release_delete(self)
        end

        def update
          Archive.instance.collection_release_update(self)
        end
    
        def template_name
          'mailinglist_collection_announcement'
        end
    
      end
    
      attr :name
      attr :display_name
      attr :website
      attr :maintainers
      attr :mailinglists
    
      def initialize(name, display_name, website, maintainer_names, mailinglists)
        @name = name
        @display_name = display_name
        @website = website
        @maintainers = maintainer_names.collect do |name|
          Maintainer.find_by_username(name)
        end
        @mailinglists = mailinglists
      end
    
      def to_json(*a)
        {
          'json_class' => self.class.name,
          'name' => name,
          'display_name' => display_name,
          'website' => website,
          'maintainers' => maintainers,
          'mailinglists' => mailinglists,
        }.to_json(*a)
      end
    
      def self.json_create(o)
        new(o['name'], o['display_name'], o['website'], o['maintainers'], o['mailinglists'])
      end
    
      def ==(other)
        other.is_a?(self.class) and other.name == name
      end
    
      def releases
        Archive.instance.collection_releases(self).sort
      end
    
      def self.find_all
        @load = lambda do [] end if @load.nil?
        @collections = @load.call unless @collections
        @collections
      end
    
      def self.find_all_by_maintainer(maintainer)
        find_all.select do |collection|
          maintainer.roles.include?('admin') or collection.maintainers.include?(maintainer)
        end
      end
    
      def self.find_by_name(name)
        find_all.find do |collection|
          collection.name == name
        end
      end
    
      def self.load(&block)
        @load = block if block_given?
      end
    end
  end
end
