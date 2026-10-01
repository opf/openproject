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

module FormConfigurations
  class AttributesController < ApplicationController
    include TypesHelper
    include OpTurbo::ComponentStream
    include WorkPackageTypes::FormConfigurationComponentStreams
    include FormConfigurations::EditorRecords

    SortableTypes = WorkPackageTypes::FormConfiguration::SortableTypes

    before_action :require_admin
    before_action :load_form_configuration
    before_action :reconcile_editor_records

    def move
      membership = @form_configuration.form_attributes.find(params.expect(:id))
      call = valid_drop_request? ? move_attribute_call(membership) : nil

      if call&.success?
        update_form_configuration_via_turbo_stream(method: :morph)
        respond_with_turbo_streams
      else
        render_invalid_move(call)
      end
    end

    private

    def move_attribute_call(membership)
      ::WorkPackageTypes::FormConfigurationRows::MoveService
        .new(user: current_user, form_configuration: @form_configuration, record: membership)
        .call(**drop_params.to_h.symbolize_keys)
    end

    # Raw params are checked where permit would hide a collection value.
    def valid_drop_request?
      case drop_params[:list_type]
      when SortableTypes::ATTRIBUTE
        drop_params[:list_id].present? && drop_params.key?(:prev_id)
      when SortableTypes::INACTIVE_ATTRIBUTE
        params[:list_id].blank?
      else
        false
      end
    end

    def drop_params
      @drop_params ||= params.permit(:list_type, :list_id, :prev_id)
    end

    def render_invalid_move(call)
      message = call&.message.presence || I18n.t(:error_invalid_list_move_anchor)
      render_error_flash_message_via_turbo_stream(message:)
      respond_with_turbo_streams(status: :unprocessable_entity)
    end

    def load_form_configuration
      @form_configuration = FormConfiguration.find(params.expect(:form_configuration_id))
    end

    def form_editor_context
      @form_editor_context ||= WorkPackageTypes::FormConfiguration::EditorContext.new(form_configuration: @form_configuration)
    end
  end
end
