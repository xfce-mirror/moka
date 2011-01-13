require 'ftools'
require 'singleton'

module Moka
  module Models
    class Archive
    
      include Singleton
    
      def root_dir
        Configuration.get(:archive_dir)
      end
    
      def excluded_classifications
        begin
          Configuration.get(:excluded_classifications)
        rescue 
          []
        end
      end
    
      def collection_dir(collection)
        File.join(root_dir, collection.name)
      end
    
      def collection_release_dir(release)
        File.join(collection_dir(release.collection), release.version)
      end
    
      def collection_source_dir(release)
        File.join(collection_release_dir(release), 'src')
      end

      def collection_fat_tarball_dir(release)
        File.join(collection_release_dir(release), 'fat_tarballs')
      end
    
      def collection_installer_dir(release)
        File.join(collection_release_dir(release), 'installers')
      end
    
      def collection_fat_tarball_basename(release)
        "#{release.collection.name}-#{release.version}.tar.bz2"
      end

      def collection_fat_tarball_filename(release)
        dirname = collection_fat_tarball_dir(release)
        basename = collection_fat_tarball_basename(release)
        File.join(dirname, basename)
      end

      def collection_releases(collection)
        releases = []
    
        if File.directory?(collection_dir(collection))
          dir = Dir.new(collection_dir(collection))
          
          versions = dir.entries.select do |entry|
            entry != '.' and entry != '..' \
              and File.directory?(File.join(collection_dir(collection), entry))
          end
    
          releases += versions.collect do |version|
            Collection::Release.new(collection, version)
          end
        end
    
        releases
      end
    
      def collection_release_add_project_release(release, project_release)
        source_dir = collection_source_dir(release)
    
        File.makedirs(source_dir) unless File.directory?(source_dir)
    
        link_target = project_release_tarball_filename(project_release)
        link_filename = File.join(source_dir, File.basename(link_target))
    
        File.delete(link_filename) if File.file?(link_filename)
        File.link(link_target, link_filename)

        checksum_files = project_release_checksum_filenames(project_release)
        for filename in checksum_files
          link_target = filename
          link_filename = File.join(source_dir, File.basename(link_target))

          File.delete(link_filename) if File.file?(link_filename)
          File.link(link_target, link_filename)
        end
      end
    
      def collection_release_remove_project_release(release, project_release)
        source_dir = collection_source_dir(release)
        tarball_basename = project_release_tarball_basename(project_release)
    
        filename = File.join(source_dir, tarball_basename)
        File.delete(filename) if File.file?(filename)
      end
    
      def collection_release_project_release_included?(release, project_release)
        source_dir = collection_source_dir(release)
    
        if File.directory?(source_dir)
          dir = Dir.new(source_dir)
    
          tarball = dir.entries.find do |entry|
            entry =~ project_release_tarball_pattern(project_release)
          end
    
          return !tarball.nil?
        end
    
        false
      end
    
      def collection_release_delete(release)
        if File.directory?(collection_release_dir(release))
          FileUtils.rm_rf(collection_release_dir(release))
        end
      end

      def collection_release_update(release)
        if File.directory?(collection_source_dir(release))
          source_dir = collection_source_dir(release)

          release_dir = collection_release_dir(release)

          source_dir = collection_source_dir(release).gsub(release_dir + '/', '')
          fat_tarball = collection_fat_tarball_filename(release)
          target_dir = File.dirname(fat_tarball)

          File.makedirs(target_dir) unless File.directory?(target_dir)
          File.delete(fat_tarball) if File.file?(fat_tarball)

          if system("cd #{release_dir} && flock --timeout=5 #{fat_tarball} tar cjf #{fat_tarball} #{source_dir}")
            update_tarball_checksums(fat_tarball)
          end
        end
      end
    
      def classification_dir(classification)
        File.join(root_dir, 'src', classification.name)
      end
    
      def classifications
        return @classifications unless @classifications.nil?
    
        @classifications = []
    
        if File.directory?(File.join(root_dir, 'src'))
          dir = Dir.new(File.join(root_dir, 'src'))
    
          names = dir.entries.select do |entry|
            entry != '.' and entry != '..' \
              and not excluded_classifications.include?(entry) \
              and File.directory?(File.join(root_dir, 'src', entry))
          end
    
          @classifications += names.collect do |name|
            Classification.new(name, File.join(root_dir, 'src', name))
          end
    
          @classifications.each do |classification|
            if File.directory?(classification_dir(classification))
              cdir = Dir.new(classification_dir(classification))
    
              classification.project_names = cdir.entries.select do |entry|
                entry != '.' and entry != '.' \
                  and File.directory?(File.join(classification_dir(classification), entry))
              end
            end
          end
        end
    
        @classifications
      end
    
      def project_dir(project)
        File.join(classification_dir(project.classification), project.name)
      end
    
      def project_branch_dir(project, branch)
        File.join(project_dir(project), branch.name)
      end
    
      def project_branches(project)
        branches = []
    
        begin
          if File.directory?(project_dir(project))
            dir = Dir.new(project_dir(project))
    
            names = dir.entries.select do |entry|
              entry != '.' and entry != '..' \
                and File.directory?(File.join(project_dir(project), entry))
            end
    
            branches += names.collect do |name|
              Project::Branch.new(project, name)
            end
          end
        rescue NoMethodError
        end
    
        branches
      end
    
      def project_branch_add_tarball(branch, file, basename)
        dir = project_branch_dir(branch.project, branch)
    
        File.makedirs(dir) unless File.directory?(dir)
    
        source_file = file.path
        target_file = File.join(dir, basename)
    
        if File.file?(target_file)
          begin
            lockfile = File.new(target_file)
            file.flock(File::LOCK_EX)

            File.move(source_file, target_file)
            File.chmod(0664, target_file)
          ensure
            lockfile.flock(File::LOCK_UN)
          end
        else
          File.move(source_file, target_file)
          File.chmod(0664, target_file)
        end
        
        update_tarball_checksums(target_file)

        project_branch_update(branch)
      end

      def update_tarball_checksums(tarball)
        basename = File.basename(tarball)

        open("#{tarball}.md5", File::CREAT|File::TRUNC|File::RDWR) do |file|
          begin
            file.flock(File::LOCK_EX)
            file.puts "#{Digest::MD5.file(tarball)}  #{basename}"
          ensure
            file.flock(File::LOCK_UN)
          end
        end
    
        open("#{tarball}.sha1", File::CREAT|File::TRUNC|File::RDWR) do |file|
          begin
            file.flock(File::LOCK_EX)
            file.puts "#{Digest::SHA1.file(tarball)}  #{basename}"
          ensure
            file.flock(File::LOCK_UN)
          end
        end
      end
    
      def project_release_from_tarball(project, tarball)
        branch = project_tarball_branch(project, tarball)
        version = project_tarball_version(project, tarball)
        Project::Release.new(branch.project, branch, version)
      end
      
      def project_branch_update(branch)
        dirname = project_branch_dir(branch.project, branch)
        begin Dir.rmdir(dirname) rescue SystemCallError end
      end
    
      def project_tarball_pattern(project)
        /^(#{project.name})-([0-9\.]+[a-zA-Z0-9\-_]+)\.tar\.(bz2|gz)$/i
      end

      def project_tarball_upload_pattern(project)
        # /^(#{project.name})-([0-9]\.[0-9])\.([0-9]\.){1,2}tar\.bz2$/i
        /^(#{project.name})-([0-9]\.[0-9]+)\.([0-9]+\.){1,2}tar\.bz2$/i
      end

      def project_release_tarball_pattern(release)
        /^(#{release.project.name})-(#{release.version})\.tar\.(bz2|gz)$/i
      end

      def project_tarball_branch(project, tarball)
        version = tarball.gsub(project_tarball_upload_pattern(project), '\2')
        Project::Branch.new(project, version)
      end
    
      def project_tarball_version(project, tarball)
        tarball.gsub(project_tarball_pattern(project), '\2')
      end
    
      def project_release_tarball_basename(release)
        source_dir = project_branch_dir(release.project, release.branch)

        if File.directory?(source_dir)
          dir = Dir.new(source_dir)

          tarball = dir.entries.find do |entry|
            entry =~ project_release_tarball_pattern(release)
          end

          return tarball unless tarball.nil?
        end

        "#{release.project.name}-#{release.version}.tar.bz2"
      end
    
      def project_release_tarball_filename(release)
        File.join(project_branch_dir(release.project, release.branch), \
                  project_release_tarball_basename(release))
      end

      def project_release_checksum_filenames(release)
        tarball_basename = project_release_tarball_basename(release)
        dirname = project_branch_dir(release.project, release.branch)

        filenames = [ 
          File.join(dirname, "#{tarball_basename}.md5"), 
          File.join(dirname, "#{tarball_basename}.sha1")
        ]
      end
    
      def project_release_delete(release)
        filename = project_release_tarball_filename(release)

        File.delete(filename) if File.file?(filename)

        checksum_filenames = project_release_checksum_filenames(release)
        for file in checksum_filenames 
          File.delete(file) if File.file?(file)
        end

        project_branch_update(release.branch)
      end
    
      def project_release_checksum(release, type)
        result = nil
    
        tarball_basename = project_release_tarball_basename(release)
        branch_dir = project_branch_dir(release.project, release.branch)
        basename = if type == Digest::MD5 then 
          "#{tarball_basename}.md5" 
        else 
          "#{tarball_basename}.sha1"
        end
    
        open(File.join(branch_dir, basename)) do |checksum_file|
          begin
            checksum_file.flock(File::LOCK_SH)
            for line in checksum_file.readlines
              checksum, tarball = line.split(' ')
              if tarball == tarball_basename
                result = checksum
                break
              end
            end
          ensure
            checksum_file.flock(File::LOCK_UN)
          end
        end
    
        result
      end
    
      def project_releases(project)
        releases = []
    
        for branch in project.branches
          if File.directory?(project_branch_dir(project, branch))
            dir = Dir.new(project_branch_dir(project, branch))
    
            tarballs = dir.entries.select do |entry|
              entry =~ project_tarball_pattern(project)
            end
    
            releases += tarballs.collect do |tarball|
              version = project_tarball_version(project, tarball)
              Project::Release.new(project, branch, version)
            end
          end
        end
    
        releases
      end
    
      def project_change_classification(project, new_classification)
        old_classification = project.classification
        old_dir = project_dir(project)
        
        project.classification = new_classification
        new_dir = project_dir(project)
    
        path = Pathname.new(new_dir)
        parent = path.parent
    
        File.makedirs(parent) unless File.directory?(parent)
    
        project.classification = old_classifcation unless File.move(old_dir, new_dir)
    
        begin 
          Dir.delete(old_dir)
        rescue SystemCallError
        end
      end
    end
  end
end
