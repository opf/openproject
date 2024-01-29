# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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

class FiltersComponent < ApplicationComponent
  options :query

  renders_many :buttons, lambda { |**system_arguments|
    system_arguments[:ml] ||= 2
    Primer::Beta::Button.new(**system_arguments)
  }

  def show_filters_section?
    params[:filters].present? && !params.key?(:hide_filters_section)
  end

  # Returns filters, active and inactive.
  # In case a filter is active, the active one will be preferred over the inactive one.
  def each_filter
    allowed_filters.map do |filter|
      active_filter = query.find_active_filter(filter.name)
      filter_active = active_filter.present?

      if filter_active
        yield active_filter, filter_active
      else
        yield filter, filter_active
      end
    end
  end

  def allowed_filters
    query
     .available_filters
  end

  def filters_count
    query.filters.count
  end
end
