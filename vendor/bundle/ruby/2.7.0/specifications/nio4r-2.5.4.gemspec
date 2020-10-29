# -*- encoding: utf-8 -*-
# stub: nio4r 2.5.4 ruby lib
# stub: ext/nio4r/extconf.rb

Gem::Specification.new do |s|
  s.name = "nio4r".freeze
  s.version = "2.5.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/socketry/nio4r/issues", "changelog_uri" => "https://github.com/socketry/nio4r/blob/master/CHANGES.md", "documentation_uri" => "https://www.rubydoc.info/gems/nio4r/2.5.4", "source_code_uri" => "https://github.com/socketry/nio4r/tree/v2.5.4", "wiki_uri" => "https://github.com/socketry/nio4r/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tony Arcieri".freeze]
  s.date = "2020-09-15"
  s.description = "Cross-platform asynchronous I/O primitives for scalable network clients and servers. Inspired by the Java NIO API, but simplified for ease-of-use.".freeze
  s.email = ["bascule@gmail.com".freeze]
  s.extensions = ["ext/nio4r/extconf.rb".freeze]
  s.files = ["ext/nio4r/extconf.rb".freeze]
  s.homepage = "https://github.com/socketry/nio4r".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "New IO for Ruby".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
