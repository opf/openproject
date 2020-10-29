require File.join File.dirname(__FILE__), 'lib', 'icalendar', 'version'

Gem::Specification.new do |s|
  s.authors = ['Ryan Ahearn']
  s.email   = ['ryan.c.ahearn@gmail.com']

  s.name = "icalendar"
  s.version = Icalendar::VERSION

  s.homepage = "https://github.com/icalendar/icalendar"
  s.platform = Gem::Platform::RUBY
  s.summary = "A ruby implementation of the iCalendar specification (RFC-5545)."
  s.description = <<-EOD
Implements the iCalendar specification (RFC-5545) in Ruby.  This allows
for the generation and parsing of .ics files, which are used by a
variety of calendaring applications.
  EOD
  s.post_install_message = <<-EOM
ActiveSupport is required for TimeWithZone support, but not required for general use.
  EOM

  s.files = `git ls-files`.split "\n"
  s.test_files = `git ls-files -- {test,spec,features}/*`.split "\n"
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename f }
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.4.0'

  s.add_dependency 'ice_cube', '~> 0.16'

  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'bundler', '~> 2.0'

  # test with all groups of tzinfo dependencies
  # tzinfo 2.x
  # s.add_development_dependency 'tzinfo', '~> 2.0'
  # s.add_development_dependency 'tzinfo-data', '~> 1.2018'
  # tzinfo 1.x
  s.add_development_dependency 'activesupport', '~> 5.2'
  s.add_development_dependency 'i18n', '~> 1.1'
  s.add_development_dependency 'tzinfo', '~> 1.2'
  s.add_development_dependency 'tzinfo-data', '~> 1.2018'
  # tzinfo 0.x
  # s.add_development_dependency 'i18n', '~> 0.7'
  # s.add_development_dependency 'tzinfo', '~> 0.3'
  # end tzinfo

  s.add_development_dependency 'timecop', '~> 0.9'
  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'simplecov', '~> 0.16'
end
