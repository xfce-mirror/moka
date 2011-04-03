require 'rubygems'

module Moka
  module Models
    class Configuration

      def self.get(option)
        @load = lambda do end if @load.nil?
        @data = {} unless @data
        @load.call(self)

        if @data.has_key?(option)
          @data[option]
        else
          raise "Unknown configuration option '#{option}'"
        end
      end

      def self.set(option, value)
        @data = {} unless @data
        @data[option] = value
      end

      def self.load(&block)
        @load = block if block_given?
      end

    end
  end
end
