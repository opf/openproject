#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module WikiFormatting
    module NullFormatter
      class Formatter
        include ERB::Util
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::TextHelper
        include ActionView::Helpers::UrlHelper

        def initialize(text)
          @text = text
        end

        def to_html(*args)
          simple_format(auto_link(CGI::escapeHTML(@text)))
        end
      end
    end
  end
end