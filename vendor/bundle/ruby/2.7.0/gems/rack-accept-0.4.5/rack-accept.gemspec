$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'rack/accept/version'

Gem::Specification.new do |s|
  s.name = 'rack-accept'
  s.version = Rack::Accept.version
  s.date = Time.now.strftime('%Y-%m-%d')

  s.summary = 'HTTP Accept* for Ruby/Rack'
  s.description = 'HTTP Accept, Accept-Charset, Accept-Encoding, and Accept-Language for Ruby/Rack'

  s.author = 'Michael Jackson'
  s.email = 'mjijackson@gmail.com'

  s.require_paths = %w< lib >

  s.files = Dir['doc/**/*'] +
    Dir['lib/**/*.rb'] +
    Dir['test/*.rb'] +
    %w< CHANGES rack-accept.gemspec Rakefile README.md >

  s.test_files = s.files.select {|path| path =~ /^test\/.*_test.rb/ }

  s.add_dependency('rack', '>= 0.4')
  s.add_development_dependency('rake')

  s.has_rdoc = true
  s.rdoc_options = %w< --line-numbers --inline-source --title Rack::Accept --main Rack::Accept >
  s.extra_rdoc_files = %w< CHANGES README.md >

  s.homepage = 'http://mjijackson.github.com/rack-accept'
end
