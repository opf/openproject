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

module Settings
  module ProjectVersions
    class IndexSubHeaderComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      options :query

      options :project

      private

      def filter_input_value
        query.find_active_filter(:name)&.values&.first
      end

      def clear_button_id = "versions-filter-clear"

      def filter_input_id = "versions-filter-name"

      def sub_header_data_attributes
        {
          controller: "filter--filters-form",
          "filter--filters-form-output-format-value": "json",
          "filter--filters-form-turbo-frame-request-value": IndexComponent::FRAME_ID,
          "filter--filters-form-clear-button-id-value": clear_button_id,
          "filter--filters-form-current-filters-value": serialized_filters
        }
      end

      def serialized_filters
        OpPrimer::QuickFilter.serialize(query.filters).to_json
      end

      def filter_input_data_attributes
        {
          turbo_permanent: true,
          "filter-name": "name",
          "filter-type": "string",
          "filter-operator": "~",
          "filter--filters-form-target": "simpleFilter filterValueContainer simpleValue"
        }
      end
    end
  end
end
