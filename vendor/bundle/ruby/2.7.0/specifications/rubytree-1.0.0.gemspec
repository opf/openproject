# -*- encoding: utf-8 -*-
# stub: rubytree 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rubytree".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Anupam Sengupta".freeze]
  s.date = "2017-12-21"
  s.description = "\n    RubyTree is a pure Ruby implementation of the generic tree data structure. It\n    provides a node-based model to store named nodes in the tree, and provides\n    simple APIs to access, modify and traverse the structure.\n\n    The implementation is node-centric, where individual nodes in the tree are the\n    primary structural elements. All common tree-traversal methods (pre-order,\n    post-order, and breadth-first) are supported.\n\n    The library mixes in the Enumerable and Comparable modules to allow access to\n    the tree as a standard collection (iteration, comparison, etc.).\n\n    A Binary tree is also provided, which provides the in-order traversal in\n    addition to the other methods.\n\n    RubyTree supports importing from, and exporting to JSON, and also supports the\n    Ruby's standard object marshaling.\n\n    This is a BSD licensed open source project, and is hosted at\n    http://github.com/evolve75/RubyTree, and is available as a standard gem from\n    http://rubygems.org/gems/rubytree.\n\n    The home page for RubyTree is at http://rubytree.anupamsg.me.\n\n".freeze
  s.email = "anupamsg@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE.md".freeze, "API-CHANGES.rdoc".freeze, "History.rdoc".freeze]
  s.files = ["API-CHANGES.rdoc".freeze, "History.rdoc".freeze, "LICENSE.md".freeze, "README.md".freeze]
  s.homepage = "http://rubytree.anupamsg.me".freeze
  s.licenses = ["BSD".freeze]
  s.post_install_message = "    ========================================================================\n                    Thank you for installing RubyTree.\n\n    Note:: As of 1.0.0, RubyTree can only support MRI Ruby >= 2.2.x\n\n    Details of the API changes are documented in the API-CHANGES file.\n    ========================================================================\n".freeze
  s.rdoc_options = ["--title".freeze, "Rubytree Documentation".freeze, "--quiet".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A generic tree data structure.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<structured_warnings>.freeze, ["~> 0.3"])
    s.add_runtime_dependency(%q<json>.freeze, ["~> 2.1"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.16"])
    s.add_development_dependency(%q<rdoc>.freeze, ["~> 6.0"])
    s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
    s.add_development_dependency(%q<rtagstask>.freeze, ["~> 0.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
  else
    s.add_dependency(%q<structured_warnings>.freeze, ["~> 0.3"])
    s.add_dependency(%q<json>.freeze, ["~> 2.1"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.16"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 6.0"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9"])
    s.add_dependency(%q<rtagstask>.freeze, ["~> 0.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
  end
end
