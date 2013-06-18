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

require 'will_paginate'

module PaginationHelper
  def pagination_links_full(paginator, count=nil, options={})
    html = ''.html_safe

    if paginator.total_entries > 0
      html << will_paginate(paginator, next_label: I18n.t(:label_next), previous_label: I18n.t(:label_next), :container => false)

      html << content_tag(:span, "(#{paginator.offset + 1} - #{paginator.offset + paginator.length}/#{paginator.total_entries})", :class => 'range')

      if per_page_links && links = per_page_links(paginator.per_page)
        html << links
      end
    end

    content_tag :p, html, :class => "pagination"
  end

  def per_page_links(selected=nil)
    links = Setting.per_page_options_array.collect do |n|
      n == selected ?
              content_tag(:span, n, :class => 'current') :
              link_to_content_update(n, params.merge(:per_page => n))
    end
    content_tag :span, :class => 'per_page_options' do
      links.size > 1 ? l(:label_display_per_page, links.join(', ')).html_safe : nil
    end
  end
end
