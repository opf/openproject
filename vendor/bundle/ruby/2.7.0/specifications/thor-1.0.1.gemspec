# -*- encoding: utf-8 -*-
# stub: thor 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "thor".freeze
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/erikhuda/thor/issues", "changelog_uri" => "https://github.com/erikhuda/thor/blob/master/CHANGELOG.md", "documentation_uri" => "http://whatisthor.com/", "source_code_uri" => "https://github.com/erikhuda/thor/tree/v1.0.1", "wiki_uri" => "https://github.com/erikhuda/thor/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yehuda Katz".freeze, "Jos\u00E9 Valim".freeze]
  s.date = "2019-12-17"
  s.description = "Thor is a toolkit for building powerful command-line interfaces.".freeze
  s.email = "ruby-thor@googlegroups.com".freeze
  s.executables = ["thor".freeze]
  s.files = ["bin/thor".freeze]
  s.homepage = "http://whatisthor.com/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Thor is a toolkit for building powerful command-line interfaces.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 1.0", "< 3"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 1.0", "< 3"])
  end
end
