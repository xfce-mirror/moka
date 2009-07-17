require 'rubygems'
require 'json'
require 'json/add/core'
require 'pony'

class Mailinglist

  attr :email
  attr :website

  def initialize(email, website)
    @email = email
    @website = website
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'email' => email,
      'website' => website
    }.to_json(*a)
  end

  def self.json_create(o)
    new(o['email'], o['website'])
  end

  def ==(other)
    other.is_a?(self.class) and other.email == email
  end
  
  def subject(release)
    "Announcement: #{release.project.name} #{release.version} released"
  end

  def announce_release(maintainer, release, greeting, message)
    erb = File.open("views/mailinglist_announcement.erb") do |file|
      ERB.new(file.read)
    end
    body = erb.result(binding)

    p body

    Pony.mail :to => email,
      :from => "#{maintainer.realname} <#{maintainer.email}>",
      :subject => subject(release),
      :body => body
  end

  def self.find_all
    load_mailinglists_on_demand
    @mailinglists
  end

  def self.find_by_email(email)
    find_all.find do |mailinglist|
      mailinglist.email == email
    end
  end

  private

    def self.load_mailinglists_on_demand
      @mailinglists = JSON.load(File.new('mailinglists.json')) unless @mailinglists
    end
end
