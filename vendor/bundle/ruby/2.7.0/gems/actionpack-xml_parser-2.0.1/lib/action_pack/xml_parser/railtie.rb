require 'action_pack/xml_parser'

module ActionPack
  class XmlParser
    class Railtie < ::Rails::Railtie
      initializer "actionpack-xml_parser.configure" do
        ActionPack::XmlParser.register
      end
    end
  end
end
