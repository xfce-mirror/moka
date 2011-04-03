require 'digest/sha1'

module Moka
  module Models
    class Maintainer
      include DataMapper::Resource

      property :username, String, :key => true
      property :realname, String
      property :password, String
      property :email,    String
      property :pubkeys,  Text

      has n, :roles, :through => Resource

      #has n, :collections, :through => Resource
      #has n, :projects, :through => Resource

      def self.authenticate(username, password)
        encrypted_password = Digest::SHA1.hexdigest(password)

        maintainer = get(username)
        if maintainer and maintainer.password == encrypted_password
          maintainer
        else
          nil
        end
      end

      def <=>(other)
        return 0 unless other.is_a?(self.class)
        username <=> other.username
      end

      def authorized?(required_roles)
        if required_roles.is_a?(String)
          required_roles = [required_roles]
        end

        matched_roles = []
        for role in roles
          matched_roles << role if required_roles.include?(role.name)
        end
        not matched_roles.empty?
      end

      def display_email
        "#{realname} <#{email}>"
      end

      def is_admin
        authorized?('admin')
      end
    end
  end
end
