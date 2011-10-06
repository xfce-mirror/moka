require 'rubygems'
require 'rake'

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name     = 'moka'
    gem.summary  = %Q{Release management web application}
    gem.email    = 'jannis@xfce.org'
    gem.homepage = 'http://git.xfce.org/admin/moka/'
    gem.authors  = ['Jannis Pohlmann', 'Nick Schermer']
    gem.files    = FileList['[A-Z]*', '{examples,lib}/**/*']

    gem.add_dependency('pony')
    gem.add_dependency('sinatra')
    gem.add_dependency('warden')
    gem.add_dependency('haml')
    gem.add_dependency('ratom')
  end
rescue LoadError
  puts 'Jeweler not available. Install it with "gem install jeweler"'
end
