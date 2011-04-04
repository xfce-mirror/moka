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

        def header(args={})
          custom_binding = binding.clone
          eval 'params = ' + args.inspect, custom_binding
          import('head', custom_binding)
        end
  
        def footer
          import('foot')
        end
  
        def import(template, custom_binding=nil)
          directory = File.expand_path(File.dirname(__FILE__))
          filename = File.join(directory, '..', 'views', "#{template}.erb")
          erb = open(filename) do |file|
            ERB.new(file.read)
          end
          erb.result(if custom_binding.nil? then binding else custom_binding end)
        end

        def view(*args)
          import(*args)
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
