# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'task_list/version'

Gem::Specification.new do |gem|
  gem.name          = "deckar01-task_list"
  gem.version       = TaskList::VERSION
  gem.authors       = ["Jared Deckard", "Matt Todd"]
  gem.email         = ["jared.deckard@gmail.com"]
  gem.description   = %q{Markdown TaskList components}
  gem.summary       = %q{Markdown TaskList components}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.0.0"

  gem.add_dependency "activesupport", "~> 4.0" if RUBY_VERSION < '2.2.2'
  gem.add_dependency "nokogiri", "~> 1.6.0" if RUBY_VERSION < '2.1.0'
  gem.add_dependency "html-pipeline"

  gem.add_development_dependency "commonmarker"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "coffee-script"
  gem.add_development_dependency "json"
  gem.add_development_dependency "rack", "~> 1.0" if RUBY_VERSION < '2.2.2'
  gem.add_development_dependency "rack" if RUBY_VERSION >= '2.2.2'
  gem.add_development_dependency "sprockets"
  gem.add_development_dependency "minitest", "~> 5.3.2"
end
