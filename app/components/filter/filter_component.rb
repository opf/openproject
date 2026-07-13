# frozen_string_literal: true

# -- copyright
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
# ++
module Filter
  class FilterComponent < ApplicationComponent
    TURBO_FRAME_ID = "filter_component"

    options :query
    # The path used for fetching the filter section lazily from the backend upon opening it.
    # If none is provided, the filters are rendered right away.
    options lazy_loaded_path: false
    options initially_expanded: false

    def filter_form(form)
      Filters::FilterFormComponent.new(builder: form, query:, allowed_filters:)
    end

    def allowed_filters
      query.available_advanced_filters
    end

    def lazy_loaded? = !!lazy_loaded_path

    def initially_expanded? = initially_expanded

    def turbo_requests? = false

    def skeleton_height
      # This is an approximation.
      # * 100 for the padding and the filter selection
      # * 40 per filter and their bottom margin. But the height of the filters vary unfortunately.
      "#{100 + (query.filters.count * 40)}px"
    end

    def filter_classes
      [
        "op-filters-form",
        "op-filters-form_top-margin",
        ("-expanded" if initially_expanded?),
        ("op-filters-form--with-footer" unless turbo_requests?)
      ].compact.join(" ")
    end

    def lazy_turbo_frame_src
      public_send(lazy_loaded_path, **params.permit(:filters, :columns, :sortBy, :id, :query_id, :project_id))
    end
  end
end
