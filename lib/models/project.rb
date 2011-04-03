module Moka
  module Models
    class Project
      include DataMapper::Resource

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

        def <=>(other)
          return 0 unless other.is_a?(self.class)
          name <=> other.name
        end

        def add_tarball(file, basename)
          Archive.instance.project_branch_add_tarball(self, file, basename)
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

        def delete
          Archive.instance.project_release_delete(self)
        end

        def template_name
          'mailinglist_project_announcement'
        end

      end

      property :name,           String, :key => true
      property :website,        String
      property :classification, String
      property :description,    Text

      has n,   :maintainers, :through => Resource

      # classification
      # mailinglists

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

      def tarball_upload_pattern
        Archive.instance.project_tarball_upload_pattern(self)
      end

      def tarball_pattern
        Archive.instance.project_tarball_pattern(self)
      end

      def release_from_tarball(tarball)
        Archive.instance.project_release_from_tarball(self, tarball)
      end

      def self.find_all_by_maintainer(maintainer)
        all()
      end
    end
  end
end
