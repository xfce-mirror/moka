require 'ftools'
require 'singleton'

class Archive

  attr_accessor :root_dir
  attr_accessor :excluded_classifications

  include Singleton

  def initialize
    @root_dir = File.dirname(__FILE__)
    @classifications_exclude = []
  end

  def collection_dir(collection)
    File.join(root_dir, collection.name)
  end

  def collection_source_dir(collection, release)
    File.join(collection_dir(collection), release.version, 'src')
  end

  def collection_installer_dir(collection, release)
    File.join(collection_dir(collection), release.version, 'installers')
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

  def classification_dir(classification)
    File.join(root_dir, classification.name)
  end

  def classifications
    return @classifications unless @classifications.nil?

    @classifications = []

    if File.directory?(root_dir)
      dir = Dir.new(root_dir)

      names = dir.entries.select do |entry|
        entry != '.' and entry != '..' \
          and not excluded_classifications.include?(entry) \
          and File.directory?(File.join(root_dir, entry))
      end

      @classifications += names.collect do |name|
        Classification.new(name, File.join(root_dir, name))
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

    begin
      Dir.rmdir(dir) 
    rescue SystemCallError
    end
  end

  def project_tarball_pattern(project)
    /(#{project.name})-([0-9.]+).tar.bz2/
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
  end

  def project_release_delete(release)
    filename = project_release_tarball_filename(release)

    File.delete(filename) if File.file?(filename)

    path = Pathname.new(filename)
    parent = path.parent

    begin
      Dir.rmdir(parent) if File.directory?(parent)
    rescue SystemCallError
    end
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
