require 'rubygems'
require 'json'
require 'json/add/core'

class Project

  class Branch
  
    attr :project
    attr :name
  
    def initialize(project, name)
      @project = project
      @name = name
    end
  
    def ==(other)
      other.is_a?(self.class) \
        and other.name == name \
        and other.project == project
    end

    def add_tarball(file, basename)
      Archive.instance.project_branch_add_tarball(self, file, basename)
    end
  
  end

  class Release

    attr :project
    attr :branch
    attr :version

    def initialize(project, branch, version)
      @project = project
      @branch = branch
      @version = version
    end

    def ==(other)
      other.is_a?(self.class) \
        and other.project == project \
        and other.branch == branch \
        and other.version == version
    end

    def tarball_basename
      Archive.instance.project_release_tarball_basename(self)
    end

    def add_tarball(file)
      Archive.instance.project_release_add_tarball(self, file)
    end

    def delete
      Archive.instance.project_release_delete(self)
    end

  end

  attr :name
  attr :maintainers
  attr :mailinglists
  attr_accessor :classification

  def initialize(name, maintainer_names, mailinglist_names)
    @name = name
    @maintainers = maintainer_names.collect do |name|
      Maintainer.find_by_username(name)
    end
    @mailinglists = mailinglist_names.collect do |name|
      Mailinglist.find_by_name(name)
    end
    @classification = Classification.find_by_project(self)
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'name' => name,
      'maintainers' => maintainers,
    }.to_json(*a)
  end

  def self.json_create(o)
    new(o['name'], o['maintainers'], o['mailinglists'])
  end

  def ==(other)
    other.is_a?(self.class) and other.name == name
  end

  def branches
    Archive.instance.project_branches(self)
  end

  def releases(branch=nil)
    Archive.instance.project_releases(self).select do |release|
      branch.nil? or release.branch == branch
    end
  end

  def classify_as(classification)
    Archive.instance.project_change_classification(self, classification)
  end

  def self.find_all
    load_projects_on_demand
    @projects
  end

  def self.find_all_by_maintainer(maintainer)
    find_all.select do |project|
      project.maintainers.include?(maintainer)
    end
  end

  def self.find_by_name(name)
    find_all.find do |project|
      project.name == name
    end
  end

  private

    def self.load_projects_on_demand
      @projects = JSON.load(File.new('projects.json')) unless @projects
    end
end
