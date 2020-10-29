# frozen_string_literal: true

module Grape
  module Formatter
    module Xml
      class << self
        def call(object, _env)
          return object.to_xml if object.respond_to?(:to_xml)
          raise Grape::Exceptions::InvalidFormatter.new(object.class, 'xml')
        end
      end
    end
  end
end
