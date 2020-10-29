# -*- encoding: utf-8 -*-
# stub: actionpack-xml_parser 2.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "actionpack-xml_parser".freeze
  s.version = "2.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Prem Sichanugrist".freeze]
  s.date = "2017-05-10"
  s.email = "s@sikac.hu".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "http://www.rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.2".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "XML parameters parser for Action Pack (removed from core in Rails 4.0)".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<actionpack>.freeze, [">= 5.0"])
    s.add_runtime_dependency(%q<railties>.freeze, [">= 5.0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<actionpack>.freeze, [">= 5.0"])
    s.add_dependency(%q<railties>.freeze, [">= 5.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
