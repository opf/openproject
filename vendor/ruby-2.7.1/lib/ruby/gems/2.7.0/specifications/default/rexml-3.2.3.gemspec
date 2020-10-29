# -*- encoding: utf-8 -*-
# stub: rexml 3.2.3 ruby lib

Gem::Specification.new do |s|
  s.name = "rexml".freeze
  s.version = "3.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kouhei Sutou".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-04-16"
  s.description = "An XML toolkit for Ruby".freeze
  s.email = ["kou@cozmixng.org".freeze]
  s.files = ["rexml/attlistdecl.rb".freeze, "rexml/attribute.rb".freeze, "rexml/cdata.rb".freeze, "rexml/child.rb".freeze, "rexml/comment.rb".freeze, "rexml/doctype.rb".freeze, "rexml/document.rb".freeze, "rexml/dtd/attlistdecl.rb".freeze, "rexml/dtd/dtd.rb".freeze, "rexml/dtd/elementdecl.rb".freeze, "rexml/dtd/entitydecl.rb".freeze, "rexml/dtd/notationdecl.rb".freeze, "rexml/element.rb".freeze, "rexml/encoding.rb".freeze, "rexml/entity.rb".freeze, "rexml/formatters/default.rb".freeze, "rexml/formatters/pretty.rb".freeze, "rexml/formatters/transitive.rb".freeze, "rexml/functions.rb".freeze, "rexml/instruction.rb".freeze, "rexml/light/node.rb".freeze, "rexml/namespace.rb".freeze, "rexml/node.rb".freeze, "rexml/output.rb".freeze, "rexml/parent.rb".freeze, "rexml/parseexception.rb".freeze, "rexml/parsers/baseparser.rb".freeze, "rexml/parsers/lightparser.rb".freeze, "rexml/parsers/pullparser.rb".freeze, "rexml/parsers/sax2parser.rb".freeze, "rexml/parsers/streamparser.rb".freeze, "rexml/parsers/treeparser.rb".freeze, "rexml/parsers/ultralightparser.rb".freeze, "rexml/parsers/xpathparser.rb".freeze, "rexml/quickpath.rb".freeze, "rexml/rexml.rb".freeze, "rexml/sax2listener.rb".freeze, "rexml/security.rb".freeze, "rexml/source.rb".freeze, "rexml/streamlistener.rb".freeze, "rexml/text.rb".freeze, "rexml/undefinednamespaceexception.rb".freeze, "rexml/validation/relaxng.rb".freeze, "rexml/validation/validation.rb".freeze, "rexml/validation/validationexception.rb".freeze, "rexml/xmldecl.rb".freeze, "rexml/xmltokens.rb".freeze, "rexml/xpath.rb".freeze, "rexml/xpath_parser.rb".freeze]
  s.homepage = "https://github.com/ruby/rexml".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "An XML toolkit for Ruby".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
