# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fog/xml/version"

Gem::Specification.new do |spec|
  spec.name          = "fog-xml"
  spec.version       = Fog::Xml::VERSION
  spec.authors       = ["Wesley Beary (geemus)", "Paul Thornthwaite (tokengeek)", "The fog team"]
  spec.email         = ["geemus@gmail.com", "tokengeek@gmail.com"]
  spec.summary       = "XML parsing for fog providers"
  spec.description   = "Extraction of the XML parsing tools shared between a
                          number of providers in the 'fog' gem"
  spec.homepage      = "https://github.com/fog/fog-xml"
  spec.license       = "MIT"

  files              = `git ls-files -z`.split("\x0")
  files.delete(".hound.yml")
  spec.files = files

  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = %w(lib)

  spec.add_dependency "fog-core"
  case RUBY_VERSION
  when /^(1\.8.*|1\.9\.[012])$/
    spec.add_dependency "nokogiri", ">= 1.5.11", "< 1.6.2"
    spec.add_development_dependency "rake", "< 11.0.0"
  when /^(1\.9\.([^012]|\d.+)|2\.0.*)$/
    spec.add_dependency "nokogiri", ">= 1.5.11", "< 1.7.0"
    spec.add_development_dependency "rake"
  else
    spec.add_dependency "nokogiri", ">= 1.5.11", "< 2.0.0"
    spec.add_development_dependency "rake"
  end
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "turn"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "coveralls" if RUBY_VERSION.to_f >= 1.9
  spec.add_development_dependency "term-ansicolor", "< 1.4.0" if RUBY_VERSION.start_with? "1.9."
  spec.add_development_dependency "tins", "< 1.7.0" if RUBY_VERSION.start_with? "1.9."
end
