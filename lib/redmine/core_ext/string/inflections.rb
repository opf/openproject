module Redmine #:nodoc:
  module CoreExtensions #:nodoc:
    module String #:nodoc:
      # Custom string inflections
      module Inflections
        def with_leading_slash
          starts_with?('/') ? self : "/#{ self }"
        end
      end
    end
  end
end
