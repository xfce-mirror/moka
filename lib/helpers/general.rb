require 'haml'

module Moka
  module Helpers
    module General
      def self.registered(app)
        app.before do 
          env[:error] = {}
        end
      
        app.helpers Helpers
      end

      module Helpers
        include Moka::Models

        def render_layout(custom_binding, &block)
          directory = File.expand_path(File.dirname(__FILE__))
          filename = File.join(directory, '..', 'views', 'layout.haml')
          engine = open(filename) do |file| Haml::Engine.new(file.read) end
          engine.render(if custom_binding.nil? then binding else custom_binding end) do
            block.call(self)
          end
        end

        def view(template, custom_binding = nil)
          render_layout(custom_binding) do 
            directory = File.expand_path(File.dirname(__FILE__))
            filename = File.join(directory, '..', 'views', "#{template}.haml")
            engine = open(filename) do |file| Haml::Engine.new(file.read) end
            engine.render(if custom_binding.nil? then binding else custom_binding end)
          end
        end

        def error_set(key, value)
          env[:error][key] = value
        end

        def error(key)
          env[:error][key]
        end

        def error_set?(key = nil)
          if key.nil?
            not env[:error].empty?
          else
            env[:error].has_key?(key)
          end
        end

      def maintainer_names(model)
        names = []
        for maintainer in model.maintainers.sort
          names << maintainer.realname
        end
        names.join(', ')
      end
      end
    end
  end
end
