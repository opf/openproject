Gem::Specification.new do |gem|
  gem.name          = 'webfinger'
  gem.version       = File.read('VERSION').delete("\n\r")
  gem.authors       = ['nov matake']
  gem.email         = ['nov@matake.jp']
  gem.description   = %q{Ruby WebFinger client library}
  gem.summary       = %q{Ruby WebFinger client library, following IETF WebFinger WG spec updates.}
  gem.homepage      = 'https://github.com/nov/webfinger'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.add_runtime_dependency 'httpclient', '>= 2.4'
  gem.add_runtime_dependency 'activesupport'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec-its'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'webmock', '>= 1.6.2'
end
