require 'rubygems'
require 'rake'

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name     = 'moka'
    gem.summary  = %Q{Release management web application}
    gem.email    = 'jannis@xfce.org'
    gem.homepage = 'http://git.xfce.org/jannis/moka'
    gem.authors  = ['Jannis Pohlmann']
    gem.files    = FileList['[A-Z]*', '{examples,lib}/**/*']

    gem.add_dependency('pony', '0.3')
    gem.add_dependency('sinatra', '0.9.2')
    gem.add_dependency('warden', '0.2.3')
    gem.add_dependency('haml', '2.2.1')
    gem.add_dependency('ratom', '0.6.2')
  end
rescue LoadError
  puts 'Jeweler not available. Install it with "gem install jeweler"'
end
