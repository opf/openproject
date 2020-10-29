# -*- encoding: utf-8 -*-
# stub: rbtree3 0.6.0 ruby ./
# stub: extconf.rb

Gem::Specification.new do |s|
  s.name = "rbtree3".freeze
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/kyrylo/rbtree3/blob/master/ChangeLog", "homepage_uri" => "https://github.com/kyrylo/rbtree3", "source_code_uri" => "https://github.com/kyrylo/rbtree3" } if s.respond_to? :metadata=
  s.require_paths = ["./".freeze]
  s.authors = ["Kyrylo Silin".freeze, "OZAWA Takuma".freeze]
  s.date = "2020-01-21"
  s.description = "A RBTree is a sorted associative collection that is implemented with a Red-Black Tree. It maps keys to values like a Hash, but maintains its elements in ascending key order. The interface is the almost identical to that of Hash.\n\nThis is a fork of the original gem that fixes various bugs on Ruby 2.3+.".freeze
  s.email = ["silin@kyrylo.org".freeze]
  s.extensions = ["extconf.rb".freeze]
  s.files = ["extconf.rb".freeze]
  s.homepage = "https://github.com/kyrylo/rbtree3".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A RBTree is a sorted associative collection that is implemented with a Red-Black Tree.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version
end
