# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "will_paginate"

module PaginationHelper
  SHOW_MORE_DEFAULT_LIMIT = 5
  SHOW_MORE_DEFAULT_INCREMENT = 20
  SHOW_MORE_MAX_LIMIT = 1000

  def pagination_links_full(paginator, params: {}, allowed_params: nil, per_page_links: true, **)
    return unless paginator.total_entries > 0

    content_tag(:div, class: ["op-pagination", { "op-pagination--single-page": paginator.total_pages <= 1 }]) do
      concat pagination_pages_section(paginator, params:, allowed_params:, **)
      concat pagination_options_section(paginator, params:, allowed_params:) if per_page_links
    end
  end

  # Returns page option used for pagination
  # based on:
  #  * offset
  #  * limit
  #  * page
  #  parameters.
  #  Prefers page over the other two and
  #  calculates page in its absence based on limit and offset.
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
  #  * per_page options value
  #  * per_page session value
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

  ##
  # For "Show more" paginated links, we want to load an initial number of items (defaulting to 5)
  # unless a higher number is provided. These values do not correspond to the per_page_options
  def show_more_limit_param(limit: nil, initial_limit: SHOW_MORE_DEFAULT_LIMIT)
    limit = limit.to_i
    if limit.zero?
      initial_limit
    else
      [limit, SHOW_MORE_MAX_LIMIT].min
    end
  end

  ##
  # Paginate an AR relation for the "show more" pagination functionality
  def show_more_pagination(paginator, limit: nil)
    paginator.paginate(page: 1, per_page: show_more_limit_param(limit:))
  end

  private

  def pagination_pages_section(paginator, params:, allowed_params:, **)
    content_tag(:div, class: "op-pagination--pages") do
      safe_join(
        [
          render_primer_pagination(paginator, params:, allowed_params:, **),
          pagination_range(paginator)
        ]
      )
    end
  end

  def render_primer_pagination(paginator, params:, allowed_params:, turbo: false, turbo_action: nil, **)
    link_arguments = {}
    link_arguments[:data] = {}
    link_arguments[:data][:turbo_stream] = true if turbo
    link_arguments[:data][:turbo_action] = turbo_action if turbo_action.present?
    link_arguments.delete(:data) if link_arguments[:data].empty?

    render(
      Primer::OpenProject::Pagination.new(
        page_count: paginator.total_pages,
        current_page: paginator.current_page,
        href_builder: ->(page) { pagination_href(page, params:, allowed_params:) },
        link_arguments:
      )
    )
  end

  def pagination_href(page, params:, allowed_params:)
    allowed_params ||= %w[filters sortBy]

    url_for(
      params
        .merge(page:)
        .merge(safe_query_params(allowed_params))
    )
  end

  def pagination_range(paginator)
    page_first = paginator.offset + 1
    page_last = paginator.offset + paginator.length
    total = paginator.total_entries

    content_tag(
      :div,
      "(#{page_first} - #{page_last}/#{total})",
      class: "op-pagination--range",
      aria: { live: "polite" }
    )
  end

  def pagination_options_section(paginator, params:, allowed_params:)
    per_page_options = Setting.per_page_options_array
    return "" if per_page_options.empty?

    allowed_params ||= %w[filters sortBy]
    content_tag(:div, class: "op-pagination--options") do
      content_tag(:nav, aria: { label: I18n.t(:"js.pagination.per_page_navigation") }) do
        pagination_options_list(
          per_page_options,
          current_per_page: paginator.per_page,
          **params.merge(safe_query_params(allowed_params))
        )
      end
    end
  end

  def pagination_options_list(per_pages, current_per_page:, **)
    safe_join [
      content_tag(:span, I18n.t(:label_per_page), class: "op-pagination--label"),
      per_pages.map { |per_page| pagination_options_item(per_page, current: per_page == current_per_page, **) }
    ]
  end

  ##
  # Constructs the 'n items per page' entries
  # determined from available options in the settings.
  def pagination_options_item(per_page, current:, **options)
    label = I18n.t("js.pagination.pages.show_per_page", number: per_page)
    aria_props = { label: }
    aria_props[:current] = "page" if current

    link_to(
      per_page,
      options.merge(page: 1, per_page:),
      class: "Page",
      aria: aria_props,
      target: "_top"
    )
  end
end
