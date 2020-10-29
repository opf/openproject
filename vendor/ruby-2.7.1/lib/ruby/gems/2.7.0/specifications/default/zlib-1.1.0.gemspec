# -*- encoding: utf-8 -*-
# stub: zlib 1.1.0 ruby lib
# stub: ext/zlib/extconf.rb

Gem::Specification.new do |s|
  s.name = "zlib".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yukihiro Matsumoto".freeze, "UENO Katsuhiro".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-04-16"
  s.description = "Ruby interface for the zlib compression/decompression library".freeze
  s.email = ["matz@ruby-lang.org".freeze, nil]
  s.extensions = ["ext/zlib/extconf.rb".freeze]
  s.files = ["ext/zlib/extconf.rb".freeze, "zlib.so".freeze]
  s.homepage = "https://github.com/ruby/zlib".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Ruby interface for the zlib compression/decompression library".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rake-compiler>.freeze, [">= 0"])
  end
end
