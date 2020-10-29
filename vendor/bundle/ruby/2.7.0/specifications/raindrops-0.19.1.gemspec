# -*- encoding: utf-8 -*-
# stub: raindrops 0.19.1 ruby lib
# stub: ext/raindrops/extconf.rb

Gem::Specification.new do |s|
  s.name = "raindrops".freeze
  s.version = "0.19.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["raindrops hackers".freeze]
  s.date = "2020-01-08"
  s.description = "raindrops is a real-time stats toolkit to show statistics for Rack HTTP\nservers.  It is designed for preforking servers such as unicorn, but\nshould support any Rack HTTP server on platforms supporting POSIX shared\nmemory.  It may also be used as a generic scoreboard for sharing atomic\ncounters across multiple processes.".freeze
  s.email = "raindrops-public@yhbt.net".freeze
  s.extensions = ["ext/raindrops/extconf.rb".freeze]
  s.extra_rdoc_files = ["README".freeze, "LICENSE".freeze, "NEWS".freeze, "ext/raindrops/raindrops.c".freeze, "ext/raindrops/linux_inet_diag.c".freeze, "ext/raindrops/tcp_info.c".freeze]
  s.files = ["LICENSE".freeze, "NEWS".freeze, "README".freeze, "ext/raindrops/extconf.rb".freeze, "ext/raindrops/linux_inet_diag.c".freeze, "ext/raindrops/raindrops.c".freeze, "ext/raindrops/tcp_info.c".freeze]
  s.homepage = "https://yhbt.net/raindrops/".freeze
  s.licenses = ["LGPL-2.1+".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "real-time stats for preforking Rack servers".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<aggregate>.freeze, ["~> 0.2"])
    s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<posix_mq>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<rack>.freeze, [">= 1.2", "< 3.0"])
  else
    s.add_dependency(%q<aggregate>.freeze, ["~> 0.2"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.0"])
    s.add_dependency(%q<posix_mq>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rack>.freeze, [">= 1.2", "< 3.0"])
  end
end
