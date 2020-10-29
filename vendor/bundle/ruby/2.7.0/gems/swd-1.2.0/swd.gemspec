Gem::Specification.new do |s|
  s.name        = 'swd'
  s.version     = File.read('VERSION')
  s.authors     = ['nov matake']
  s.email       = ['nov@matake.jp']
  s.homepage    = 'https://github.com/nov/swd'
  s.summary     = %q{SWD (Simple Web Discovery) Client Library}
  s.description = %q{SWD (Simple Web Discovery) Client Library}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.add_runtime_dependency 'httpclient', '>= 2.4'
  s.add_runtime_dependency 'activesupport', '>= 3'
  s.add_runtime_dependency 'attr_required', '>= 0.0.5'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'simplecov'
end
