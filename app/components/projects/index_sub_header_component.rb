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

module Projects
  # rubocop:disable OpenProject/AddPreviewForViewComponent
  class IndexSubHeaderComponent < ApplicationComponent
    # rubocop:enable OpenProject/AddPreviewForViewComponent
    include ApplicationHelper
    include OpTurbo::Streamable

    def initialize(query:, current_user:, disable_buttons: nil)
      super
      @query = query
      @current_user = current_user
      @disable_buttons = disable_buttons
    end

    def self.wrapper_key
      "projects-index-sub-header"
    end

    def filter_input_value
      @query.find_active_filter(:name_and_identifier)&.values&.first
    end

    def sub_header_data_attributes
      {
        controller: "filter--filters-form",
        "application-target": "dynamic",
        "filter--filters-form-perform-turbo-requests-value": true,
        "filter--filters-form-clear-button-id-value": clear_button_id
      }
    end

    def filter_input_data_attributes
      {
        "filter-name": "name_and_identifier",
        "filter-type": "string",
        "filter-operator": "~",
        "filter--filters-form-target": "simpleFilter filterValueContainer simpleValue"
      }
    end

    def clear_button_id
      "project-filters-form-clear-button"
    end
  end
end
