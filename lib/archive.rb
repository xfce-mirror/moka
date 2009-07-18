require 'ftools'
require 'singleton'

class Archive

  include Singleton

  def root_dir
    Configuration.get.archive_dir
  end

  def excluded_classifications
    Configuration.get.excluded_classifications
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

  def collection_installer_dir(release)
    File.join(collection_release_dir(release), 'installers')
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

    File.link(link_target, link_filename)
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
        entry == project_release_tarball_basename(project_release)
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

    branches
  end

  def project_branch_add_tarball(branch, file, basename)
    dir = project_branch_dir(branch.project, branch)

    File.makedirs(dir) unless File.directory?(dir)

    source_file = file.path
    target_file = File.join(dir, basename)

    File.move(source_file, target_file)

    project_branch_update(branch)
  end

  def project_branch_release_from_tarball(branch, tarball)
    version = project_tarball_version(branch.project, tarball)
    Project::Release.new(branch.project, branch, version)
  end
  
  def project_branch_update(branch)
    dirname = project_branch_dir(branch.project, branch)

    if File.directory?(dirname)
      dir = Dir.new(dirname)

      tarballs = dir.entries.select do |entry|
        entry =~ project_tarball_pattern(branch.project)
      end

      open(File.join(dirname, "MD5SUMS"), "w+") do |checksum_file|
        for tarball in tarballs
          open(File.join(dirname, tarball)) do |tarball_file|
            checksum = Digest::MD5.hexdigest(tarball_file.read)
            checksum_file.puts("#{checksum} #{tarball}")
          end
        end
      end

      open(File.join(dirname, "SHA1SUMS"), "w+") do |checksum_file|
        for tarball in tarballs
          open(File.join(dirname, tarball)) do |tarball_file|
            checksum = Digest::SHA1.hexdigest(tarball_file.read)
            checksum_file.puts("#{checksum} #{tarball}")
          end
        end
      end
    end

    begin Dir.rmdir(dir) rescue SystemCallError end
  end

  def project_tarball_pattern(project)
    /^(#{project.name})-([0-9.]+).tar.bz2$/
  end

  def project_tarball_version(project, tarball)
    tarball.gsub(project_tarball_pattern(project), '\2')
  end

  def project_release_tarball_basename(release)
    "#{release.project.name}-#{release.version}.tar.bz2"
  end

  def project_release_tarball_filename(release)
    File.join(project_branch_dir(release.project, release.branch), \
              project_release_tarball_basename(release))
  end

  def project_release_add_tarball(release, file)
    source_file = file.path
    target_file = project_release_tarball_filename(release)

    path = Pathname.new(target_file)
    parent = path.parent

    File.makedirs(parent) unless File.directory?(parent)
    File.delete(target_file) if File.file?(target_file)
    File.move(source_file, target_file)

    project_branch_update(release.branch)
  end

  def project_release_delete(release)
    filename = project_release_tarball_filename(release)

    File.delete(filename) if File.file?(filename)

    project_branch_update(release.branch)
  end

  def project_release_checksum(release, type)
    result = nil

    tarball_basename = project_release_tarball_basename(release)
    branch_dir = project_branch_dir(release.project, release.branch)
    basename = if type == Digest::MD5 then 'MD5SUMS' else 'SHA1SUMS' end

    open(File.join(branch_dir, basename)) do |checksum_file|
      for line in checksum_file.readlines
        checksum, tarball = line.split(' ')
        if tarball == tarball_basename
          result = checksum
          break
        end
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
