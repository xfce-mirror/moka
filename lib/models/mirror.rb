module Moka
  module Models
    class Mirror
    
      attr :url
    
      def initialize(url)
        @url = url
      end
    
      def to_json(*a)
        {
          'json_class' => self.class.name,
          'url' => url
        }.to_json(*a)
      end
    
      def self.json_create(o)
        new(o['url'])
      end
    
      def download_url(release)
        if release.is_a?(Collection::Release)
          dir  = Archive.instance.collection_source_dir(release)
        else
          dir = Archive.instance.project_branch_dir(release.project, release.branch)
        end
        dir.gsub(Archive.instance.root_dir, url)
      end

      def fat_tarball_url(release)
        dir = Archive.instance.collection_fat_tarball_dir(release)
        dir.gsub(Archive.instance.root_dir, url)
      end
    
      def self.find_all
        @load = lambda do [] end if @load.nil?
        @mirrors = @load.call unless @mirrors
        @mirrors
      end
    
      def self.load(&block)
        @load = block if block_given?
      end
    
    end
  end
end
