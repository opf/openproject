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
  class FormConfigurationGroupsTabController < BaseTabController
    include TypesHelper
    include OpTurbo::ComponentStream
    include WorkPackageTypes::FormConfigurationComponentStreams

    TEMPORARY_GROUP_KEY = "__new_form_configuration_group__"

    def edit
      update_main_content_via_turbo_stream(editing_group_key: group_key_param)

      respond_with_turbo_streams
    end

    def add_group
      render_temporary_group_editor

      respond_with_turbo_streams
    end

    def create
      call = create_group_call

      if call.success?
        update_form_configuration_via_turbo_stream
      else
        render_create_error(call)
      end

      respond_with_turbo_streams(status: turbo_status_for(call))
    end

    def cancel_edit
      if temporary_group_key?(group_key_param)
        update_form_configuration_via_turbo_stream
        respond_with_turbo_streams
        return
      end

      group = find_group(group_key_param)
      return head :not_found if group.nil?

      update_main_content_via_turbo_stream
      respond_with_turbo_streams
    end

    def update
      call = rename_group_call

      if call.success?
        update_form_configuration_via_turbo_stream
      else
        render_existing_group_update_error(call)
      end

      respond_with_turbo_streams(status: turbo_status_for(call))
    end

    def destroy
      call = ::WorkPackageTypes::FormConfigurationGroups::DeleteService
        .new(user: current_user, type: @type, group_key: group_key_param)
        .call

      if call.success?
        update_form_configuration_via_turbo_stream
      else
        render_form_configuration_error(call)
      end

      respond_with_turbo_streams(status: turbo_status_for(call))
    end

    def drop
      call = ::WorkPackageTypes::FormConfigurationGroups::UpdateService
        .new(user: current_user, type: @type, group_key: group_key_param)
        .call(position: params[:position])

      if call.success?
        update_main_content_via_turbo_stream
      else
        render_form_configuration_error(call)
      end

      respond_with_turbo_streams(status: turbo_status_for(call))
    end

    def move
      call = ::WorkPackageTypes::FormConfigurationGroups::UpdateService
        .new(user: current_user, type: @type, group_key: group_key_param)
        .call(move_to: params[:move_to])

      if call.success?
        update_main_content_via_turbo_stream
      else
        render_form_configuration_error(call)
      end

      respond_with_turbo_streams(status: turbo_status_for(call))
    end

    def update_query
      call = ::WorkPackageTypes::FormConfigurationGroups::UpdateService
        .new(user: current_user, type: @type, group_key: group_key_param)
        .call(query_props: params[:query])

      if call.success?
        head :ok
      else
        render_form_configuration_error(call)
        respond_with_turbo_streams(status: turbo_status_for(call))
      end
    end

    private

    def group_params
      params.expect(group: %i[name group_type query])
    end

    def find_group(key)
      @type.attribute_groups.find do |group|
        [
          group.key,
          group.display_name,
          group.translated_key
        ].compact.map(&:to_s).include?(key.to_s)
      end
    end

    def group_key_param
      params[:key] || params[:id]
    end

    def temporary_group_key?(key)
      key.to_s == TEMPORARY_GROUP_KEY
    end

    def temporary_group(group_type:, query:, name: "")
      {
        key: TEMPORARY_GROUP_KEY,
        type: group_type.to_s,
        name:,
        attributes: [],
        query:,
        temporary: true
      }
    end

    def turbo_status_for(call)
      call.success? ? :ok : :unprocessable_entity
    end

    def create_group_call
      ::WorkPackageTypes::FormConfigurationGroups::CreateService
        .new(user: current_user, type: @type)
        .call(
          group_type: group_params[:group_type],
          name: group_params[:name],
          query_props: group_params[:query]
        )
    end

    def rename_group_call
      ::WorkPackageTypes::FormConfigurationGroups::UpdateService
        .new(user: current_user, type: @type, group_key: group_key_param)
        .call(name: group_params[:name])
    end

    def render_create_error(call)
      @type.reload
      group = temporary_group(
        group_type: group_params[:group_type],
        query: group_params[:query],
        name: group_params[:name].to_s
      )

      render_temporary_group_editor(
        group:,
        form_model: group_form_model(group:, validation_message: call.errors.map(&:message).to_sentence)
      )
    end

    def render_existing_group_update_error(call)
      @type.reload
      group = active_groups_for_form.find { |active_group| active_group[:key].to_s == group_key_param.to_s }

      update_main_content_via_turbo_stream(
        editing_group_key: group_key_param,
        form_model: group_form_model(
          group:,
          name: group_params[:name].to_s,
          validation_message: call.errors.map(&:message).to_sentence
        )
      )
    end

    def render_temporary_group_editor(group: temporary_group(group_type: params[:group_type], query: params[:query]),
                                      form_model: nil)
      update_main_content_via_turbo_stream(
        groups: [group] + active_groups_for_form,
        editing_group_key: TEMPORARY_GROUP_KEY,
        form_model:
      )
    end

    def group_form_model(group:, name: group[:name], validation_message: nil)
      WorkPackageTypes::FormConfiguration::GroupFormModel.from_group(group, name:, validation_message:)
    end
  end
end
