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

module Users
  class IndexSubHeaderComponent < ApplicationComponent
    include ApplicationHelper

    def initialize(query:)
      super
      @query = query
    end

    def filter_input_value
      @query.find_active_filter(:any_name_attribute)&.values&.first
    end

    def sub_header_data_attributes
      {
        controller: "filter--filters-form",
        "filter--filters-form-perform-turbo-requests-value": true,
        "filter--filters-form-clear-button-id-value": clear_button_id,
        "filter--filters-form-display-filters-value": filters_expanded?
      }
    end

    def filter_input_data_attributes
      {
        "filter-name": "any_name_attribute",
        "filter-type": "string",
        "filter-operator": "~",
        "filter--filters-form-target": "simpleFilter filterValueContainer simpleValue"
      }
    end

    def clear_button_id
      "user-filters-form-clear-button"
    end

    def filters_expanded?
      params[:filters].present?
    end
  end
end
