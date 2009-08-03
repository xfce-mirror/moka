require 'digest/sha1'

module Moka
  module Models
    class Maintainer
    
      attr_accessor :username
      attr_accessor :realname
      attr_accessor :password
      attr_accessor :email
      attr_accessor :roles
    
      def initialize(username, realname, password, email, roles)
        @username = username
        @realname = realname
        @password = password
        @email = email
        @roles = if roles.nil? then [] else roles end
      end
    
      def to_json(*a)
        {
          'json_class' => self.class.name,
          'username' => username,
          'realname' => realname,
          'password' => password,
          'email' => email,
          'roles' => roles
        }.to_json(*a)
      end
    
      def self.json_create(o)
        new(o['username'], o['realname'], o['password'], o['email'], o['roles'])
      end
    
      def ==(other)
        other.is_a?(self.class) and other.username == username
      end

      def display_email
        "#{realname} <#{email}>"
      end

      def save
        self.class.do_save(self)
      end

      def self.use_http_auth=(value)
        @use_http_auth = value
      end

      def self.use_http_auth?
        !@use_http_auth.nil? and @use_http_auth
      end
    
      def self.find_all
        @load = lambda do [] end if @load.nil?
        @maintainers = @load.call unless @maintainers
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

      def self.load(&block)
        @load = block if block_given?
      end

      def self.save(&block)
        @save = block if block_given?
      end

      def self.reload_all
        @maintainers = nil
        find_all
      end

      def self.do_save(maintainer)
        @save = lambda do end if @save.nil?
        @save.call(maintainer)
      end
    end
  end
end
