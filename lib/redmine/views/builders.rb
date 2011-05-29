module Redmine
  module Views
    module Builders
      def self.for(format, &block)
        builder = case format
          when 'xml',  :xml;  Builders::Xml.new
          when 'json', :json; Builders::Json.new
          else; raise "No builder for format #{format}"
        end
        if block
          block.call(builder)
        else
          builder
        end
      end
    end
  end
end
