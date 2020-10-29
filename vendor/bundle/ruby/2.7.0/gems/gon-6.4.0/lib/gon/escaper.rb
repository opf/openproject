class Gon
  module Escaper
    extend ActionView::Helpers::JavaScriptHelper
    extend ActionView::Helpers::TagHelper

    class << self

      def escape_unicode(javascript)
        if javascript
          result = escape_line_separator(javascript)
          javascript.html_safe? ? result.html_safe : result
        end
      end

      def javascript_tag(content, type, cdata, nonce)
        options = {}
        options.merge!( { type: 'text/javascript' } ) if type
        options.merge!( { nonce: nonce } ) if nonce

        content_tag(:script, javascript_cdata_section(content, cdata).html_safe, options)
      end

      def javascript_cdata_section(content, cdata)
        if cdata
          "\n//#{cdata_section("\n#{content}\n//")}\n"
        else
          "\n#{content}\n"
        end
      end

      private

      def escape_line_separator(javascript)
        javascript.gsub(/\\u2028/u, '&#x2028;')
      end

    end
  end
end
