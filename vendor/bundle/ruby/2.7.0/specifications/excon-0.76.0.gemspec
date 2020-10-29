# -*- encoding: utf-8 -*-
# stub: excon 0.76.0 ruby lib

Gem::Specification.new do |s|
  s.name = "excon".freeze
  s.version = "0.76.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/excon/excon/issues", "changelog_uri" => "https://github.com/excon/excon/blob/master/changelog.txt", "documentation_uri" => "https://github.com/excon/excon/blob/master/README.md", "homepage_uri" => "https://github.com/excon/excon", "source_code_uri" => "https://github.com/excon/excon", "wiki_uri" => "https://github.com/excon/excon/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["dpiddy (Dan Peterson)".freeze, "geemus (Wesley Beary)".freeze, "nextmat (Matt Sanders)".freeze]
  s.date = "2020-07-27"
  s.description = "EXtended http(s) CONnections".freeze
  s.email = "geemus@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze, "CONTRIBUTORS.md".freeze, "CONTRIBUTING.md".freeze]
  s.files = ["CONTRIBUTING.md".freeze, "CONTRIBUTORS.md".freeze, "README.md".freeze]
  s.homepage = "https://github.com/excon/excon".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "speed, persistence, http(s)".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rspec>.freeze, [">= 3.5.0"])
    s.add_development_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_development_dependency(%q<delorean>.freeze, [">= 0"])
    s.add_development_dependency(%q<eventmachine>.freeze, [">= 1.0.4"])
    s.add_development_dependency(%q<open4>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
    s.add_development_dependency(%q<shindo>.freeze, [">= 0"])
    s.add_development_dependency(%q<sinatra>.freeze, [">= 0"])
    s.add_development_dependency(%q<sinatra-contrib>.freeze, [">= 0"])
    s.add_development_dependency(%q<json>.freeze, [">= 1.8.5"])
    s.add_development_dependency(%q<puma>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rspec>.freeze, [">= 3.5.0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<delorean>.freeze, [">= 0"])
    s.add_dependency(%q<eventmachine>.freeze, [">= 1.0.4"])
    s.add_dependency(%q<open4>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rdoc>.freeze, [">= 0"])
    s.add_dependency(%q<shindo>.freeze, [">= 0"])
    s.add_dependency(%q<sinatra>.freeze, [">= 0"])
    s.add_dependency(%q<sinatra-contrib>.freeze, [">= 0"])
    s.add_dependency(%q<json>.freeze, [">= 1.8.5"])
    s.add_dependency(%q<puma>.freeze, [">= 0"])
  end
end
