#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'will_paginate'

module PaginationHelper
  def pagination_links_full(paginator, options = {})
    merged_options = { next_label: I18n.t(:label_next),
                       previous_label: I18n.t(:label_previous),
                       container: true }.merge(options)

    html = ''.html_safe

    if paginator.total_entries > 0
      html << will_paginate(paginator, merged_options.merge(container: false))

      html << content_tag(:span, "(#{paginator.offset + 1} - #{paginator.offset + paginator.length}/#{paginator.total_entries})", class: 'range')

      if per_page_links && links = per_page_links(paginator.per_page, merged_options[:params] || params)
        html << links
      end
    end

    merged_options[:container] ?
      content_tag(:p, html, class: 'legacy-pagination') :
      html
  end

  def per_page_links(selected = nil, options = params)
    links = Setting.per_page_options_array.map do |n|
      n == selected ?
              content_tag(:span, n, class: 'current') :
              link_to_content_update(n, options.merge(page: 1, per_page: n))
    end
    content_tag :span, class: 'per_page_options' do
      links.size > 1 ? l(:label_display_per_page, links.join(', ')).html_safe : nil
    end
  end

  # Returns page option used for pagination
  # based on:
  #  * offset
  #  * limit
  #  * page
  #  parameters.
  #  Preferes page over the other two and
  #  calculates page in it's absence based on limit and offset.
  #  Return 1 if all else fails.

  def page_param(options = params)
    page = if options[:page]

             options[:page].to_i

           elsif options[:offset] && options[:limit]

             begin
               # + 1 as page is not 0 but 1 based
               options[:offset].to_i / per_page_param(options) + 1
              rescue ZeroDivisionError
                1
             end

           else

             1

           end

    page > 0 ?
      page :
      1
  end

  # Returns per_page option used for pagination
  # based on:
  #  * per_page session value
  #  * per_page options value
  #  * limit options value
  #  in that order
  #  Return smallest possible setting if all else fails.

  def per_page_param(options = params)
    per_page_candidates = [options[:per_page].to_i, session[:per_page].to_i, options[:limit].to_i]

    unless (union = per_page_candidates & Setting.per_page_options_array).empty?
      session[:per_page] = union.first

      union.first
    else
      Setting.per_page_options_array.sort.first
    end
  end
end
