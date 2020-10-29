module ActionView
  module Helpers
    module JavaScriptHelper
      def escape_javascript(s)
        EscapeUtils.escape_javascript(s.to_s)
      end
    end
  end
end
