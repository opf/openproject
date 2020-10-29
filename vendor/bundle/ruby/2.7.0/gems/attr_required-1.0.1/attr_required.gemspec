Gem::Specification.new do |s|
  s.name = "attr_required"
  s.version = File.read("VERSION")
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["nov matake"]
  s.description = %q{attr_required and attr_optional}
  s.summary = %q{attr_required and attr_optional}
  s.email = "nov@matake.jp"
  s.extra_rdoc_files = ["LICENSE", "README.rdoc"]
  s.license = 'MIT'
  s.rdoc_options = ["--charset=UTF-8"]
  s.homepage = "http://github.com/nov/attr_required"
  s.require_paths = ["lib"]
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.add_development_dependency "rake"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "rspec"
end
