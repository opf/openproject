#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'will_paginate'

module PaginationHelper
  def pagination_links_full(paginator, options = {})
    return unless paginator.total_entries > 0

    pagination_options = default_options.merge(options)

    content_tag(:div, class: 'op-pagination') do
      content = content_tag(:nav,
                            pagination_entries(paginator, pagination_options),
                            class: 'op-pagination--pages')

      if pagination_options[:per_page_links]
        content << pagination_option_links(paginator, pagination_options)
      end

      content.html_safe
    end
  end

  def pagination_option_links(paginator, pagination_options)
    option_links = pagination_settings(paginator,
                                       pagination_options[:params]
                                        .merge(safe_query_params(%w{filters sortBy expand})))

    content_tag(:div, option_links, class: 'op-pagination--options')
  end

  ##
  # Builds the pagination nav with pages and range
  def pagination_entries(paginator, options)
    page_first = paginator.offset + 1
    page_last = paginator.offset + paginator.length
    total = paginator.total_entries

    content_tag(:ul, class: 'op-pagination--items op-pagination--items_start') do
      # will_paginate will return nil early when no pages available
      content = will_paginate(paginator, options) || ''

      range = "(#{page_first} - #{page_last}/#{total})"
      content << content_tag(:li, range, class: 'op-pagination--range', title: range)

      content.html_safe
    end
  end

  ##
  # Builds pagination options (range).
  def pagination_settings(paginator, options)
    links = per_page_links(paginator, options)

    if links.size > 1
      label = I18n.t(:label_per_page)
      content_tag(:ul, class: 'op-pagination--items op-pagination--items_end') do
        content_tag(:li, label + ':', class: 'op-pagination--label', title: label) + links
      end
    end
  end

  ##
  # Constructs the 'n items per page' entries
  # determined from available options in the settings.
  def per_page_links(paginator, options)
    Setting.per_page_options_array.inject('') do |html, n|
      if n == paginator.per_page
        html + content_tag(:li, n, class: 'op-pagination--item op-pagination--item_current')
      else
        link = link_to_content_update(n, options.merge(page: 1, per_page: n), { class: 'op-pagination--item-link' })
        html + content_tag(:li, link.html_safe, class: 'op-pagination--item')
      end
    end.html_safe
  end

  # Returns page option used for pagination
  # based on:
  #  * offset
  #  * limit
  #  * page
  #  parameters.
  #  Prefers page over the other two and
  #  calculates page in it's absence based on limit and offset.
  #  Return 1 if all else fails.

  def page_param(options = params)
    page = if options[:page]

             options[:page].to_i

           elsif options[:offset] && options[:limit]

             begin
               # + 1 as page is not 0 but 1 based
               (options[:offset].to_i / per_page_param(options)) + 1
             rescue ZeroDivisionError
               1
             end

           else

             1

           end

    if page > 0
      page
    else
      1
    end
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

    if (union = per_page_candidates & Setting.per_page_options_array).empty?
      Setting.per_page_options_array.min
    else
      session[:per_page] = union.first

      union.first
    end
  end

  class LinkRenderer < ::WillPaginate::ActionView::LinkRenderer
    def to_html
      pagination.inject('') do |html, item|
        html + (item.is_a?(Integer) ? page_number(item) : send(item))
      end.html_safe
    end

    protected

    def merge_get_params(url_params)
      params = super
      params.except(*blocked_url_params)
    end

    def page_number(page)
      if page == current_page
        tag(:li, page, class: 'op-pagination--item op-pagination--item_current')
      else
        tag(:li, link(page, page, { class: 'op-pagination--item-link' }), class: 'op-pagination--item')
      end
    end

    def gap
      tag(:li, '&#x2026;', class: 'op-pagination--space')
    end

    def previous_page
      num = @collection.current_page > 1 && (@collection.current_page - 1)
      previous_or_next_page(num, I18n.t(:label_previous), 'prev')
    end

    def next_page
      num = @collection.current_page < total_pages && (@collection.current_page + 1)
      previous_or_next_page(num, I18n.t(:label_next), 'next')
    end

    def previous_or_next_page(page, text, class_suffix)
      if page
        tag(:li,
            link(text, page, { class: 'op-pagination--item-link op-pagination--item-link_' + class_suffix }),
            class: 'op-pagination--item op-pagination--item_' + class_suffix)
      else
        ''
      end
    end

    def blocked_url_params
      @options[:blocked_url_params] || [] # rubocop:disable Rails/HelperInstanceVariable
    end
  end

  private

  def default_options
    {
      renderer: LinkRenderer,
      per_page_links: true,
      params: {}
    }
  end
end
