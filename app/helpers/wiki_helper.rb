#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module WikiHelper
  def wiki_page_options_for_select(pages, selected = nil, parent = nil, level = 0)
    pages = pages.group_by(&:parent) unless pages.is_a?(Hash)
    s = ''
    if pages.has_key?(parent)
      pages[parent].each do |page|
        attrs = "value='#{page.id}'"
        attrs << " selected='selected'" if selected == page
        indent = (level > 0) ? ('&nbsp;' * level * 2 + '&#187; ') : nil

        s << "<option #{attrs}>#{indent}#{h page.pretty_title}</option>\n" +
               wiki_page_options_for_select(pages, selected, page, level + 1)
      end
    end
    s
  end

  def breadcrumb_for_page(page, action = nil)
    if action
      related_pages = page.ancestors.reverse + [page]
      breadcrumb_paths(*(related_pages.collect{|parent| link_to h(parent.breadcrumb_title), {:id => parent.title, :project_id => parent.project, :action => "show"}} + [action]))
    else
      related_pages = page.ancestors.reverse
      breadcrumb_paths(*(related_pages.collect{|parent| link_to h(parent.breadcrumb_title), {:id => parent.title, :project_id => parent.project, :action => "show"}} + [h(page.breadcrumb_title)]))
    end
  end
end
