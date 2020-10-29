lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gon/version'

Gem::Specification.new do |s|
  s.name        = 'gon'
  s.version     = Gon::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['gazay']
  s.licenses    = ['MIT']
  s.email       = ['alex.gaziev@gmail.com']
  s.homepage    = 'https://github.com/gazay/gon'
  s.summary     = %q{Get your Rails variables in your JS}
  s.description = %q{If you need to send some data to your js files and you don't want to do this with long way trough views and parsing - use this force!}

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.2.0'
  s.add_dependency 'actionpack', '>= 3.0.20'
  s.add_dependency 'i18n', '>= 0.7'
  s.add_dependency 'request_store', '>= 1.0'
  s.add_dependency 'multi_json'
  s.add_development_dependency 'rabl', '0.11.3'
  s.add_development_dependency 'rabl-rails'
  s.add_development_dependency 'rspec', '>= 3.0'
  s.add_development_dependency 'jbuilder'
  s.add_development_dependency 'railties', '>= 3.0.20'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-byebug'
end
