require 'active_support'
require 'active_support/core_ext/hash/conversions'
require 'action_dispatch'
require 'action_dispatch/http/request'
require 'action_pack/xml_parser/version'

module ActionPack
  class XmlParser
    def self.register
      original_parsers = ActionDispatch::Request.parameter_parsers
      ActionDispatch::Request.parameter_parsers = original_parsers.merge(Mime[:xml].symbol => self)
    end

    def self.call(raw_post)
      Hash.from_xml(raw_post) || {}
    end
  end
end
