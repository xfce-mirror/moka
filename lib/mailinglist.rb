require 'rubygems'
require 'json'
require 'json/add/core'

class Mailinglist

  attr :name
  attr :email
  attr :website

  def initialize(name, email, website)
    @name = name
    @email = email
    @website = website
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'name' => name,
      'email' => email,
      'website' => website
    }.to_json(*a)
  end

  def self.json_create(o)
    new(o['name'], o['email'], o['website'])
  end

  def ==(other)
    other.is_a?(self.class) and other.name == name
  end

  def self.find_all
    load_mailinglists_on_demand
    @mailinglists
  end

  def self.find_by_name(name)
    find_all.find do |mailinglist|
      mailinglist.name == name
    end
  end

  private

    def self.load_mailinglists_on_demand
      @mailinglists = JSON.load(File.new('mailinglists.json')) unless @mailinglists
    end
end
