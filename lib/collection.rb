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

  end

  attr :name
  attr :display_name
  attr :maintainers
  attr :projects

  def initialize(name, display_name, maintainer_names, project_names)
    @name = name
    @display_name = display_name
    @maintainers = maintainer_names.collect do |name|
      Maintainer.find_by_username(name)
    end
    @projects = project_names.collect do |name|
      Project.find_by_name(name)
    end
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'name' => name,
      'display_name' => display_name,
      'maintainers' => maintainers,
      'projects' => projects
    }.to_json(*a)
  end

  def self.json_create(o)
    new(o['name'], o['display_name'], o['maintainers'], o['projects'])
  end

  def releases
    Archive.instance.collection_releases(self)
  end

  def remove_project(release, project)
    source_dir = source_dir(release)
    pattern = project.tarball_pattern

    if File.directory?(source_dir)
      dir = Dir.new(source_dir)
      for entry in dir.entries
        next unless entry =~ pattern
        File.delete(File.join(source_dir, entry))
      end
    end
  end

  def add_project(release, project, branch, project_release)
    source_dir = source_dir(release)
    
    File.makedirs(source_dir) unless File.directory?(source_dir)

    target_filename = project.tarball_filename(project_release, branch)
    source_filename = File.join(source_dir, project.tarball_basename(project_release))

    puts "#{source_filename} -> #{target_filename}"

    File.link(target_filename, source_filename)
  end

  def included_project_version(release, project)
    if File.directory?(source_dir(release))
      pattern = project.tarball_pattern
      dir = Dir.new(source_dir(release))

      for entry in dir.entries
        next unless entry =~ pattern
        return entry.gsub(pattern, '\2')
      end
    end
    nil
  end

  def source_dir(release)
    Archive.instance.collection_source_dir(self, release)
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

