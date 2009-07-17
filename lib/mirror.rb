require 'rubygems'
require 'json'
require 'json/add/core'

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
    dir = Archive.instance.project_branch_dir(release.project, release.branch)
    dir.gsub(Archive.instance.root_dir, url)
  end

  def self.find_all
    load_mirrors_on_demand
    @mirrors
  end

  private

    def self.load_mirrors_on_demand
      @mirrors = JSON.load(File.new('mirrors.json')) unless @mirrors
    end

end
