module Moka
  module Models
    class Group
      include DataMapper::Resource

      property :name,        String, :key => true
      property :desc, String

      has n,   :projects, :through => Resource
    end
  end
end
