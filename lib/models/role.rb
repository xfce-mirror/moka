module Moka
  module Models
    class Role
      include DataMapper::Resource

      property :name, String, :key => true

      has n,   :maintainers, :through => Resource
    end
  end
end
