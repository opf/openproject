# -*- encoding: utf-8 -*-
require File.expand_path('../lib/activerecord-import/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Zach Dennis"]
  gem.email         = ["zach.dennis@gmail.com"]
  gem.summary       = "Bulk insert extension for ActiveRecord"
  gem.description   = "A library for bulk inserting data using ActiveRecord."
  gem.homepage      = "http://github.com/zdennis/activerecord-import"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "activerecord-import"
  gem.require_paths = ["lib"]
  gem.version       = ActiveRecord::Import::VERSION

  gem.required_ruby_version = ">= 2.0.0"

  gem.add_runtime_dependency "activerecord", ">= 3.2"
  gem.add_development_dependency "rake"
end
