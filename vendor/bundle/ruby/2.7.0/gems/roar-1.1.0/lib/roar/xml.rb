require 'roar/representer'
require 'roar/hypermedia'
require 'representable/xml'

module Roar
  # Includes #from_xml and #to_xml into your represented object.
  # In addition to that, some more options are available when declaring properties.
  module XML
    def self.included(base)
      base.class_eval do
        include Representer # Roar::Representer, this is needed for Rails URL helpers
        include Representable::XML

        extend ClassMethods
        include InstanceMethods # otherwise Representable overrides our #to_xml.
      end
    end

    module InstanceMethods
      # Generic entry-point for rendering.
      def serialize(*args)
        to_xml(*args)
      end

      def deserialize(*args)
        from_xml(*args)
      end
    end


    module ClassMethods
      include Representable::XML::ClassMethods

      def links_definition_options
        # FIXME: this doesn't belong into the generic XML representer.
        {
          :as => :link,
          :class        => Hypermedia::Hyperlink,
          :extend       => XML::HyperlinkRepresenter,
          :exec_context => :decorator,
          collection: true
          } # TODO: merge with JSON.
      end
    end


    require 'representable/xml/hash'
    module HyperlinkRepresenter
      include Representable::XML::AttributeHash

      self.representation_wrap = :link
    end
  end
end
