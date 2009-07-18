require 'rubygems'
require 'json'
require 'json/add/core'

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

    def add_project_release(release)
      Archive.instance.collection_release_add_project_release(self, release)
    end
    
    def remove_project_release(release)
      Archive.instance.collection_release_remove_project_release(self, release)
    end

    def included_project_release(project)
      project.releases.find do |release| 
        Archive.instance.collection_release_project_release_included?(self, release)
      end
    end

    def delete
      Archive.instance.collection_release_delete(self)
    end

  end

  attr :name
  attr :display_name
  attr :maintainers

  def initialize(name, display_name, maintainer_names)
    @name = name
    @display_name = display_name
    @maintainers = maintainer_names.collect do |name|
      Maintainer.find_by_username(name)
    end
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'name' => name,
      'display_name' => display_name,
      'maintainers' => maintainers,
    }.to_json(*a)
  end

  def self.json_create(o)
    new(o['name'], o['display_name'], o['maintainers'])
  end

  def releases
    Archive.instance.collection_releases(self)
  end

  def self.find_all
    load_collections_on_demand
    @collections
  end

  def self.find_all_by_maintainer(maintainer)
    find_all.select do |collection|
      collection.maintainers.include?(maintainer)
    end
  end

  def self.find_by_name(name)
    find_all.find do |collection|
      collection.name == name
    end
  end

  private

    def self.load_collections_on_demand
      @collections = JSON.load(File.new('collections.json')) unless @collections
    end
end

