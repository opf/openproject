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
  module FormConfigurationComponentStreams
    extend ActiveSupport::Concern

    private

    def update_form_configuration_via_turbo_stream(**)
      update_main_content_via_turbo_stream(**)
      update_inactive_attributes_via_turbo_stream
    end

    def update_main_content_via_turbo_stream(groups: active_groups_for_form, editing_group_key: nil, form_model: nil)
      ee_available = EnterpriseToken.allows_to?(:edit_attribute_groups)
      group_components = build_group_components(
        groups:,
        ee_available:,
        editing_group_key:,
        form_model:
      )

      update_via_turbo_stream(
        component: WorkPackageTypes::FormConfiguration::MainContentComponent.new(
          type: @type,
          group_components:,
          ee_available:
        )
      )
    end

    def update_inactive_attributes_via_turbo_stream
      replace_via_turbo_stream(
        component: WorkPackageTypes::FormConfiguration::InactiveAttributesListComponent.new(
          inactive_attributes: form_configuration_groups(@type)[:inactives],
          type: @type
        ),
        target: "type-form-configuration-inactive-container"
      )
    end

    def render_form_configuration_error(call)
      render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.to_sentence)
    end

    def build_group_components(groups:, ee_available:, editing_group_key:, form_model:)
      groups.map.with_index do |group, index|
        is_editing = editing_group_key.present? && group[:key].to_s == editing_group_key.to_s

        WorkPackageTypes::FormConfiguration::GroupComponent.new(
          group:,
          type: @type,
          ee_available:,
          first: index.zero?,
          last: index == groups.length - 1,
          edit_mode: is_editing,
          form_model: (form_model if is_editing)
        )
      end
    end

    def active_groups_for_form
      form_configuration_groups(@type)[:actives].reject { |group| group[:key].to_s == "__empty" }
    end
  end
end
