# -*- encoding: utf-8 -*-
# stub: nokogumbo 2.0.2 ruby lib
# stub: ext/nokogumbo/extconf.rb

Gem::Specification.new do |s|
  s.name = "nokogumbo".freeze
  s.version = "2.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rubys/nokogumbo/issues", "changelog_uri" => "https://github.com/rubys/nokogumbo/blob/master/CHANGELOG.md", "homepage_uri" => "https://github.com/rubys/nokogumbo/#readme", "source_code_uri" => "https://github.com/rubys/nokogumbo" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sam Ruby".freeze, "Stephen Checkoway".freeze]
  s.date = "2019-11-19"
  s.description = "Nokogumbo allows a Ruby program to invoke the Gumbo HTML5 parser and access the result as a Nokogiri parsed document.".freeze
  s.email = ["rubys@intertwingly.net".freeze, "s@pahtak.org".freeze]
  s.extensions = ["ext/nokogumbo/extconf.rb".freeze]
  s.files = ["ext/nokogumbo/extconf.rb".freeze]
  s.homepage = "https://github.com/rubys/nokogumbo/#readme".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Nokogiri interface to the Gumbo HTML5 parser".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.8", ">= 1.8.4"])
  else
    s.add_dependency(%q<nokogiri>.freeze, ["~> 1.8", ">= 1.8.4"])
  end
end
