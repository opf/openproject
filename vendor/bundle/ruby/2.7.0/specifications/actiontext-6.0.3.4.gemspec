# -*- encoding: utf-8 -*-
# stub: actiontext 6.0.3.4 ruby lib

Gem::Specification.new do |s|
  s.name = "actiontext".freeze
  s.version = "6.0.3.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/blob/v6.0.3.4/actiontext/CHANGELOG.md", "documentation_uri" => "https://api.rubyonrails.org/v6.0.3.4/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "source_code_uri" => "https://github.com/rails/rails/tree/v6.0.3.4/actiontext" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Javan Makhmali".freeze, "Sam Stephenson".freeze, "David Heinemeier Hansson".freeze]
  s.date = "2020-10-07"
  s.description = "Edit and display rich text in Rails applications.".freeze
  s.email = ["javan@javan.us".freeze, "sstephenson@gmail.com".freeze, "david@loudthinking.com".freeze]
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Rich text framework.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activesupport>.freeze, ["= 6.0.3.4"])
    s.add_runtime_dependency(%q<activerecord>.freeze, ["= 6.0.3.4"])
    s.add_runtime_dependency(%q<activestorage>.freeze, ["= 6.0.3.4"])
    s.add_runtime_dependency(%q<actionpack>.freeze, ["= 6.0.3.4"])
    s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.8.5"])
  else
    s.add_dependency(%q<activesupport>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<activerecord>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<activestorage>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<actionpack>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<nokogiri>.freeze, [">= 1.8.5"])
  end
end
