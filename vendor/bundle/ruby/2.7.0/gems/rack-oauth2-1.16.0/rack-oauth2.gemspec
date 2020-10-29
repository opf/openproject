Gem::Specification.new do |s|
  s.name = 'rack-oauth2'
  s.version = File.read('VERSION')
  s.authors = ['nov matake']
  s.description = %q{OAuth 2.0 Server & Client Library. Both Bearer and MAC token type are supported.}
  s.summary = %q{OAuth 2.0 Server & Client Library - Both Bearer and MAC token type are supported}
  s.email = 'nov@matake.jp'
  s.extra_rdoc_files = ['LICENSE', 'README.rdoc']
  s.rdoc_options = ['--charset=UTF-8']
  s.homepage = 'http://github.com/nov/rack-oauth2'
  s.license = 'MIT'
  s.require_paths = ['lib']
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.add_runtime_dependency 'rack', '>= 2.1.0'
  s.add_runtime_dependency 'httpclient'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'attr_required'
  s.add_runtime_dependency 'json-jwt', '>= 1.11.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'webmock'
end
