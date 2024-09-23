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
  # rubocop:disable OpenProject/AddPreviewForViewComponent
  class FilterComponent < ApplicationComponent
    # rubocop:enable OpenProject/AddPreviewForViewComponent
    options :query
    options always_visible: false

    def show_filters_section?
      always_visible || params[:filters].present?
    end

    # Returns filters, active and inactive.
    # In case a filter is active, the active one will be preferred over the inactive one.
    def each_filter
      allowed_filters.each do |filter|
        active_filter = query.find_active_filter(filter.name)
        additional_attributes = additional_filter_attributes(filter)

        yield active_filter.presence || filter, active_filter.present?, additional_attributes
      end
    end

    def allowed_filters
      query
        .available_advanced_filters
    end

    protected

    # With this method we can pass additional options for each type of filter into the frontend. This is especially
    # useful when we want to pass options for the autocompleter components.
    #
    # When the method is overwritten in a subclass, the subclass should call super(filter) to get the default attributes.
    #
    # @param filter [QueryFilter] the filter for which we want to pass additional attributes
    # @return [Hash] the additional attributes for the filter, that will be yielded in the each_filter method
    def additional_filter_attributes(filter)
      case filter
      when Queries::Filters::Shared::ProjectFilter::Required,
           Queries::Filters::Shared::ProjectFilter::Optional
        {
          autocomplete_options: {
            component: "opce-project-autocompleter",
            resource: "projects",
            filters: [
              { name: "active", operator: "=", values: ["t"] }
            ]
          }
        }
      else
        {}
      end
    end
  end
end
