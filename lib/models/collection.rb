module Moka
  module Models
    class Collection
      include DataMapper::Resource

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

        def update_checksums
          Archive.instance.collection_release_update_checksums(self)
        end

        def template_name
          'mailinglist_collection_announcement'
        end

      end

      property :name,         String, :key => true
      property :display_name, String
      property :website,      String

      has n, :maintainers, :through => Resource
      #has n, :maintainers, :through => Resource
      #has n, :mailinglists, :through => Resource
      #belongs_to :maintainer

      def ==(other)
        other.is_a?(self.class) and other.name == name
      end

      def releases
        Archive.instance.collection_releases(self).sort
      end

      def self.find_all_by_maintainer(maintainer)
        all()
      end
    end
  end
end
