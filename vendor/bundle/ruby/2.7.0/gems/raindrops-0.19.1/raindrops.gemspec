# -*- encoding: binary -*-
manifest = File.exist?('.manifest') ?
  IO.readlines('.manifest').map!(&:chomp!) : `git ls-files`.split("\n")
test_files = manifest.grep(%r{\Atest/test_.*\.rb\z})

Gem::Specification.new do |s|
  s.name = %q{raindrops}
  s.version = (ENV["VERSION"] ||= '0.18.0').dup
  s.authors = ["raindrops hackers"]
  s.description = File.read('README').split("\n\n")[1]
  s.email = %q{raindrops-public@yhbt.net}
  s.extensions = %w(ext/raindrops/extconf.rb)
  s.extra_rdoc_files = IO.readlines('.document').map!(&:chomp!).keep_if do |f|
    File.exist?(f)
  end
  s.files = manifest
  s.homepage = 'https://yhbt.net/raindrops/'
  s.summary = 'real-time stats for preforking Rack servers'
  s.required_ruby_version = '>= 1.9.3'
  s.test_files = test_files
  s.add_development_dependency('aggregate', '~> 0.2')
  s.add_development_dependency('test-unit', '~> 3.0')
  s.add_development_dependency('posix_mq', '~> 2.0')
  s.add_development_dependency('rack', [ '>= 1.2', '< 3.0' ])
  s.licenses = %w(LGPL-2.1+)
end
