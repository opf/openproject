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

module WorkPackageTypes
  class FormConfigurationComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(type:, form_attributes:, no_filter_query:)
      super(type)
      @type = type
      @groups = form_attributes[:actives].reject { |g| g[:key].to_s == "__empty" }
      @inactive_attributes = form_attributes[:inactives]
      @no_filter_query = no_filter_query
    end

    def ee_available?
      EnterpriseToken.allows_to?(:edit_attribute_groups)
    end

    def wrapper_data
      {
        controller: "admin--type-form-configuration--main admin--type-form-configuration--rows-drag-and-drop",
        "admin--type-form-configuration--main-no-filter-query-value": @no_filter_query,
        "admin--type-form-configuration--main-add-group-url-value": add_group_type_form_configuration_groups_path(@type),
        "admin--type-form-configuration--main-groups-url-value": type_form_configuration_groups_path(@type),
        "admin--type-form-configuration--rows-drag-and-drop-handle-selector-value": ".attribute-handle"
      }
    end

    def active_list_data
      {
        controller: "admin--type-form-configuration--drag-and-drop",
        "admin--type-form-configuration--drag-and-drop-handle-selector-value": ".group-handle",
        "admin--type-form-configuration--drag-and-drop-target": "scrollContainer",
        "admin--type-form-configuration--rows-drag-and-drop-target": "scrollContainer"
      }
    end

    def group_components
      @groups.map.with_index do |group, i|
        WorkPackageTypes::FormConfiguration::GroupComponent.new(
          group:,
          type: @type,
          ee_available: ee_available?,
          first: i == 0,
          last: i == @groups.length - 1
        )
      end
    end
  end
end
