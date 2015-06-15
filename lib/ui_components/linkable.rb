module UiComponents
  module Linkable
    module InstanceMethods
      attr_accessor :text, :icon

      # additional anchor tag attributes (HTML5)
      attr_accessor :href, :hreflang, :media, :rel, :target, :type

      def tag(attributes = {})
        {
          href: nil,
          hreflang: nil,
          media: nil,
          rel: nil,
          target: nil,
          type: nil
        }.each_pair do |var, default|
          send("#{var}=", attributes.fetch(var, default))
        end
        super
      end

      def tag_attributes
        super.merge(

          href: href,
          hreflang: hreflang,
          media: media,
          rel: rel,
          target: target,
          type: type
        )
      end

      def text!(attributes = {})
        value = attributes.fetch :text, ''
        send 'text=', value
      end

      def icon!(attributes = {})
        value = attributes.fetch :icon, nil
        send 'icon=', value
      end

      def icon_and_text
        capture do
          concat icon
          concat text
        end
      end

      def icon
        return '' unless @icon
        content_tag :i, '', class: "button--icon icon-#{@icon}"
      end

      def text
        content_tag :span, @text, class: 'button--text'
      end
    end

    def self.included(receiver)
      receiver.send :include, InstanceMethods
    end
  end
end
