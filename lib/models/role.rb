module Moka
  module Models
    class Role
      include DataMapper::Resource

      property :name, String, :key => true
    end
  end
end
