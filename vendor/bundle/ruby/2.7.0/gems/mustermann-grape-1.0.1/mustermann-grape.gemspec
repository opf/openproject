# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'mustermann/grape/version'

Gem::Specification.new do |s|
  s.name                  = 'mustermann-grape'
  s.version               = MustermannGrape::VERSION
  s.authors               = ['namusyaka', 'Konstantin Haase', 'Daniel Doubrovkine']
  s.email                 = 'namusyaka@gmail.com'
  s.homepage              = 'https://github.com/ruby-grape/mustermann-grape'
  s.summary               = 'Grape syntax for Mustermann'
  s.description           = 'Adds Grape style patterns to Mustermman'
  s.license               = 'MIT'
  s.required_ruby_version = '>= 2.1.0'
  s.files                 = `git ls-files`.split("\n")
  s.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables           = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.add_dependency 'mustermann', '>= 1.0.0'
end
