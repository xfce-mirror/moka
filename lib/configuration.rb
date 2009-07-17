require 'rubygems'
require 'json'
require 'json/add/core'

class Configuration

  attr :identica
  attr :moka_url
  attr :archive_dir
  attr :excluded_classifications

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'identica' => identica,
      'moka_url' => moka_url,
      'archive_dir' => archive_dir,
      'excluded_classifications' => excluded_classifications
    }.to_json(*a)
  end

  def self.json_create(o)
    new(o['identica'], 
        o['moka_url'],
        o['archive_dir'], 
        o['excluded_classifications'])
  end

  def self.get
    @instance = JSON.load(File.new('configuration.json')) unless @instance
    @instance
  end

  private

    def initialize(identica, moka_url, archive_dir, excluded_classifications)
      @identica = identica
      @moka_url = moka_url
      @archive_dir = archive_dir
      @excluded_classifications = excluded_classifications
    end

end
