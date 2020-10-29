# -*- encoding: utf-8 -*-
# stub: rss 0.2.8 ruby lib

Gem::Specification.new do |s|
  s.name = "rss".freeze
  s.version = "0.2.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kouhei Sutou".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-04-16"
  s.description = "Family of libraries that support various formats of XML \"feeds\".".freeze
  s.email = ["kou@cozmixng.org".freeze]
  s.files = ["rss.rb".freeze, "rss/0.9.rb".freeze, "rss/1.0.rb".freeze, "rss/2.0.rb".freeze, "rss/atom.rb".freeze, "rss/content.rb".freeze, "rss/content/1.0.rb".freeze, "rss/content/2.0.rb".freeze, "rss/converter.rb".freeze, "rss/dublincore.rb".freeze, "rss/dublincore/1.0.rb".freeze, "rss/dublincore/2.0.rb".freeze, "rss/dublincore/atom.rb".freeze, "rss/image.rb".freeze, "rss/itunes.rb".freeze, "rss/maker.rb".freeze, "rss/maker/0.9.rb".freeze, "rss/maker/1.0.rb".freeze, "rss/maker/2.0.rb".freeze, "rss/maker/atom.rb".freeze, "rss/maker/base.rb".freeze, "rss/maker/content.rb".freeze, "rss/maker/dublincore.rb".freeze, "rss/maker/entry.rb".freeze, "rss/maker/feed.rb".freeze, "rss/maker/image.rb".freeze, "rss/maker/itunes.rb".freeze, "rss/maker/slash.rb".freeze, "rss/maker/syndication.rb".freeze, "rss/maker/taxonomy.rb".freeze, "rss/maker/trackback.rb".freeze, "rss/parser.rb".freeze, "rss/rexmlparser.rb".freeze, "rss/rss.rb".freeze, "rss/slash.rb".freeze, "rss/syndication.rb".freeze, "rss/taxonomy.rb".freeze, "rss/trackback.rb".freeze, "rss/utils.rb".freeze, "rss/version.rb".freeze, "rss/xml-stylesheet.rb".freeze, "rss/xml.rb".freeze, "rss/xmlparser.rb".freeze, "rss/xmlscanner.rb".freeze]
  s.homepage = "https://github.com/ruby/rss".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Family of libraries that support various formats of XML \"feeds\".".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
  end
end
