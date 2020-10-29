# -*- encoding: utf-8 -*-
# stub: unicorn-worker-killer 0.4.4 ruby lib

Gem::Specification.new do |s|
  s.name = "unicorn-worker-killer".freeze
  s.version = "0.4.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kazuki Ohta".freeze, "Sadayuki Furuhashi".freeze, "Jonathan Clem".freeze]
  s.date = "2015-11-13"
  s.description = "Kill unicorn workers by memory and request counts".freeze
  s.email = ["kazuki.ohta@gmail.com".freeze, "frsyuki@gmail.com".freeze, "jonathan@jclem.net".freeze]
  s.homepage = "https://github.com/kzk/unicorn-worker-killer".freeze
  s.licenses = ["GPLv2+".freeze, "Ruby 1.8".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Kill unicorn workers by memory and request counts".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<unicorn>.freeze, [">= 4", "< 6"])
    s.add_runtime_dependency(%q<get_process_mem>.freeze, ["~> 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0.9.2"])
  else
    s.add_dependency(%q<unicorn>.freeze, [">= 4", "< 6"])
    s.add_dependency(%q<get_process_mem>.freeze, ["~> 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0.9.2"])
  end
end
