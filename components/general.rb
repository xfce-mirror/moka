module Sinatra
  module Component
    module General
      module Helpers
        def header(args={})
          custom_binding = binding.clone
          eval 'params = ' + args.inspect, custom_binding
          import('head', custom_binding)
        end
  
        def footer
          import('foot')
        end
  
        def import(template, custom_binding=nil)
          erb = File.open("views/#{template}.erb") do |file|
            ERB.new(file.read)
          end
          erb.result(if custom_binding.nil? then binding else custom_binding end)
        end
      end
    end
  end
end
