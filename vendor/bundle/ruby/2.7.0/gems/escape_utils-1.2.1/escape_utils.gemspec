require './lib/escape_utils/version' unless defined? EscapeUtils::VERSION

Gem::Specification.new do |s|
  s.name = %q{escape_utils}
  s.version = EscapeUtils::VERSION
  s.authors = ["Brian Lopez"]
  s.email = %q{seniorlopez@gmail.com}
  s.extensions = ["ext/escape_utils/extconf.rb"]
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{https://github.com/brianmario/escape_utils}
  s.license = %q{MIT}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{Faster string escaping routines for your web apps}
  s.description = %q{Quickly perform HTML, URL, URI and Javascript escaping/unescaping}
  s.test_files = `git ls-files test`.split("\n")

  s.required_ruby_version = ">= 1.9.3"

  # tests
  s.add_development_dependency 'rake-compiler', ">= 0.7.5"
  s.add_development_dependency 'minitest', ">= 5.0.0"
  # benchmarks
  s.add_development_dependency 'benchmark-ips'
  s.add_development_dependency 'rack'
  s.add_development_dependency 'haml'
  s.add_development_dependency 'fast_xs'
  s.add_development_dependency 'actionpack'
  s.add_development_dependency 'url_escape'
end
