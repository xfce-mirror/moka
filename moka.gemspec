# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{moka}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jannis Pohlmann"]
  s.date = %q{2009-07-19}
  s.email = %q{jannis@xfce.org}
  s.files = [
    "AUTHORS",
     "COPYING",
     "Rakefile",
     "VERSION.yml",
     "examples/one-man-one-project/config.ru",
     "examples/one-man-one-project/project_release_mail.erb",
     "lib/controllers/authentication.rb",
     "lib/controllers/collections.rb",
     "lib/controllers/projects.rb",
     "lib/helpers/general.rb",
     "lib/middleware/feeds.rb",
     "lib/middleware/identica.rb",
     "lib/middleware/mailinglists.rb",
     "lib/models/archive.rb",
     "lib/models/classification.rb",
     "lib/models/collection.rb",
     "lib/models/configuration.rb",
     "lib/models/maintainer.rb",
     "lib/models/mirror.rb",
     "lib/models/project.rb",
     "lib/moka.rb",
     "lib/views/auth_login.erb",
     "lib/views/collection_delete.erb",
     "lib/views/collection_new_release.erb",
     "lib/views/collection_release.erb",
     "lib/views/foot.erb",
     "lib/views/head.erb",
     "lib/views/index.erb",
     "lib/views/manage_releases.erb",
     "lib/views/manage_releases_collections.erb",
     "lib/views/permission_denied.erb",
     "lib/views/project.erb",
     "lib/views/project_branch_new_release.erb",
     "lib/views/project_new_release.erb",
     "lib/views/project_release_delete.erb",
     "lib/views/project_release_update.erb",
     "lib/views/stylesheet.sass"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://git.xfce.org/jannis/moka}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Release management web application}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<pony>, ["= 0.3"])
      s.add_runtime_dependency(%q<sinatra>, ["= 0.9.2"])
      s.add_runtime_dependency(%q<warden>, ["= 0.2.3"])
      s.add_runtime_dependency(%q<haml>, ["= 2.2.1"])
      s.add_runtime_dependency(%q<ratom>, ["= 0.6.2"])
    else
      s.add_dependency(%q<pony>, ["= 0.3"])
      s.add_dependency(%q<sinatra>, ["= 0.9.2"])
      s.add_dependency(%q<warden>, ["= 0.2.3"])
      s.add_dependency(%q<haml>, ["= 2.2.1"])
      s.add_dependency(%q<ratom>, ["= 0.6.2"])
    end
  else
    s.add_dependency(%q<pony>, ["= 0.3"])
    s.add_dependency(%q<sinatra>, ["= 0.9.2"])
    s.add_dependency(%q<warden>, ["= 0.2.3"])
    s.add_dependency(%q<haml>, ["= 2.2.1"])
    s.add_dependency(%q<ratom>, ["= 0.6.2"])
  end
end
