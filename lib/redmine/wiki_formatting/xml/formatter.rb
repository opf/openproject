require 'loofah'

module Redmine
  module WikiFormatting
    module Xml
      class Formatter
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::TextHelper
        include ActionView::Helpers::UrlHelper

        def initialize(text)
          @text = text
        end

        def to_html(*args)
          args.include?(:edit) ? with_edit_transformation(@text).to_s : with_release_transformation(@text).to_s
        end

        def with_edit_transformation(text)
          common_transformation(text)
        end

        def with_release_transformation(text)
          common_transformation(text)
        end

        def common_transformation(text)
          Loofah.fragment(@text).scrub!(:prune)
        end
      end
    end
  end
end