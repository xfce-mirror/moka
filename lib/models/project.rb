module Moka
  module Models
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
    
        def release_from_tarball(tarball)
          Archive.instance.project_branch_release_from_tarball(self, tarball)
        end
    
        def has_release?(release)
          result = project.releases.find do |prelease|
            prelease.branch == self and prelease == release
          end
          not result.nil?
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
    
        def checksum(type)
          Archive.instance.project_release_checksum(self, type)
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
    
        def template_name
          'mailinglist_project_announcement'
        end
    
      end
    
      attr :name
      attr :website
      attr :maintainers
      attr :mailinglists
      attr_accessor :classification
    
      def initialize(name, website, maintainer_names, mailinglists)
        @name = name
        @website = website
        @maintainers = maintainer_names.collect do |name|
          Maintainer.find_by_username(name)
        end
        @mailinglists = mailinglists
        @classification = Classification.find_by_project(self)
      end
    
      def to_json(*a)
        {
          'json_class' => self.class.name,
          'name' => name,
          'website' => website,
          'maintainers' => maintainers,
          'mailinglists' => mailinglists,
        }.to_json(*a)
      end
    
      def self.json_create(o)
        new(o['name'], o['website'], o['maintainers'], o['mailinglists'])
      end
    
      def ==(other)
        other.is_a?(self.class) and other.name == name
      end
    
      def <=>(other)
        return 0 unless other.is_a?(self.class)
        name <=> other.name
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
    
      def tarball_pattern
        Archive.instance.project_tarball_pattern(self)
      end
    
      def self.find_all
        @load = lambda do [] end if @load.nil?
        @projects = @load.call unless @projects
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
    
      def self.load(&block)
        @load = block if block_given?
      end
    end
  end
end
