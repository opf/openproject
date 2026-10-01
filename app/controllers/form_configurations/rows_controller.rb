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
  class RowsController < ApplicationController
    include TypesHelper
    include OpTurbo::ComponentStream
    include FormConfigurations::EditorRecords
    include WorkPackageTypes::FormConfigurationComponentStreams

    before_action :require_admin
    before_action :load_form_configuration
    before_action :reconcile_editor_records

    def move
      respond_to_row_update(row_update_service.call(move_to: params[:move_to]))
    end

    def drop
      respond_to_row_update(row_update_service.call(target_id: params[:target_id], position: params[:position]))
    end

    def destroy
      call = ::WorkPackageTypes::FormConfigurationRows::DeleteService
        .new(user: current_user, form_configuration: @form_configuration, row_key: params[:row_key])
        .call

      respond_to_row_update(call)
    end

    private

    def row_update_service
      ::WorkPackageTypes::FormConfigurationRows::UpdateService
        .new(user: current_user, form_configuration: @form_configuration, row_key: params[:row_key])
    end

    def respond_to_row_update(call)
      if call.success?
        update_form_configuration_via_turbo_stream
      else
        render_form_configuration_error(call)
      end

      respond_with_turbo_streams(status: call.success? ? :ok : :unprocessable_entity)
    end

    def load_form_configuration
      @form_configuration = FormConfiguration.find(params.expect(:form_configuration_id))
    end

    def form_editor_context
      @form_editor_context ||= WorkPackageTypes::FormConfiguration::EditorContext.new(form_configuration: @form_configuration)
    end
  end
end
