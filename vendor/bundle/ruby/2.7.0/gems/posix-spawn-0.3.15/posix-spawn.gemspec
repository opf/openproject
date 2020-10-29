require File.expand_path('../lib/posix/spawn/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'posix-spawn'
  s.version = POSIX::Spawn::VERSION

  s.summary = 'posix_spawnp(2) for ruby'
  s.description = 'posix-spawn uses posix_spawnp(2) for faster process spawning'

  s.homepage = 'https://github.com/rtomayko/posix-spawn'

  s.authors = ['Ryan Tomayko', 'Aman Gupta']
  s.email = ['r@tomayko.com', 'aman@tmm1.net']
  s.licenses = ['MIT']

  s.add_development_dependency 'rake-compiler', '0.7.6'
  s.add_development_dependency 'minitest', '>= 4'

  s.extensions = ['ext/extconf.rb']
  s.executables << 'posix-spawn-benchmark'
  s.require_paths = ['lib']

  s.files = `git ls-files`.split("\n")
  s.extra_rdoc_files = %w[ COPYING HACKING ]
end
