module EscapeUtils
  module HtmlSafety
    if "".respond_to? :html_safe?
      def _escape_html(s)
        if s.html_safe?
          s.to_s.html_safe
        else
          EscapeUtils.escape_html(s.to_s).html_safe
        end
      end
    else
      def _escape_html(s)
        EscapeUtils.escape_html(s.to_s)
      end
    end
  end
end
