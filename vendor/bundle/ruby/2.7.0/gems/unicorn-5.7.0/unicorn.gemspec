# -*- encoding: binary -*-
manifest = File.exist?('.manifest') ?
  IO.readlines('.manifest').map!(&:chomp!) : `git ls-files`.split("\n")

# don't bother with tests that fork, not worth our time to get working
# with `gem check -t` ... (of course we care for them when testing with
# GNU make when they can run in parallel)
test_files = manifest.grep(%r{\Atest/unit/test_.*\.rb\z}).map do |f|
  File.readlines(f).grep(/\bfork\b/).empty? ? f : nil
end.compact

Gem::Specification.new do |s|
  s.name = %q{unicorn}
  s.version = (ENV['VERSION'] || '5.7.0').dup
  s.authors = ['unicorn hackers']
  s.summary = 'Rack HTTP server for fast clients and Unix'
  s.description = File.read('README').split("\n\n")[1]
  s.email = %q{unicorn-public@yhbt.net}
  s.executables = %w(unicorn unicorn_rails)
  s.extensions = %w(ext/unicorn_http/extconf.rb)
  s.extra_rdoc_files = IO.readlines('.document').map!(&:chomp!).keep_if do |f|
    File.exist?(f)
  end
  s.files = manifest
  s.homepage = 'https://yhbt.net/unicorn/'
  s.test_files = test_files

  # 1.9.3 is the minumum supported version. We don't specify
  # a maximum version to make it easier to test pre-releases,
  # but we do warn users if they install unicorn on an untested
  # version in extconf.rb
  s.required_ruby_version = ">= 1.9.3"

  # We do not have a hard dependency on rack, it's possible to load
  # things which respond to #call.  HTTP status lines in responses
  # won't have descriptive text, only the numeric status.
  s.add_development_dependency(%q<rack>)

  s.add_dependency(%q<kgio>, '~> 2.6')
  s.add_dependency(%q<raindrops>, '~> 0.7')

  s.add_development_dependency('test-unit', '~> 3.0')

  # Note: To avoid ambiguity, we intentionally avoid the SPDX-compatible
  # 'Ruby' here since Ruby 1.9.3 switched to BSD-2-Clause, but we
  # inherited our license from Mongrel when Ruby was at 1.8.
  # We cannot automatically switch licenses when Ruby changes.
  s.licenses = ['GPL-2.0+', 'Ruby-1.8']
end
