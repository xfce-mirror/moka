require 'rubygems'
require 'json'
require 'json/add/core'
require 'digest/sha1'

class Maintainer

  attr :username
  attr :realname
  attr :password
  attr :email

  def initialize(username, realname, password, email)
    @username = username
    @realname = realname
    @password = password
    @email = email
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'username' => username,
      'realname' => realname,
      'password' => password,
      'email' => email
    }.to_json(*a)
  end

  def self.json_create(o)
    new(o['username'], o['realname'], o['password'], o['email'])
  end

  def ==(other)
    other.is_a?(self.class) \
      and other.username == username \
      and other.realname == realname \
      and other.password == password \
      and other.email == email
  end

  def self.find_all
    load_maintainers_on_demand
    @maintainers
  end

  def self.find_by_username(username)
    find_all.find do |maintainer|
      maintainer.username == username
    end
  end

  def self.authenticate(username, password)
    encrypted_password = Digest::SHA1.hexdigest(password)
    
    find_all.find do |maintainer|
      maintainer.username == username \
        and maintainer.password == encrypted_password
    end
  end

  private

    def self.load_maintainers_on_demand
      @maintainers = JSON.load(File.new('maintainers.json')) unless @maintainers
    end

end
