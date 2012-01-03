#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module Views
    class OtherFormatsBuilder
      def initialize(view)
        @view = view
      end

      def link_to(name, options={})
        url = { :format => name.to_s.downcase }.merge(options.delete(:url) || {})
        caption = options.delete(:caption) || name
        html_options = { :class => name.to_s.downcase, :rel => 'nofollow' }.merge(options)
        @view.content_tag('span', @view.link_to(caption, url, html_options))
      end
    end
  end
end
